import Foundation
import CNSDK

public final class ScannerSDK: @unchecked Sendable {
    public static let shared = ScannerSDK()

    private let lock = NSLock()
    private var discoveryHub = StreamHub<DiscoveredDevice>()
    private var discoveryFailureHub = StreamHub<DiscoveryFailure>()
    private var sessionFailureHub = StreamHub<SessionFailure>()
    private var debugHub = StreamHub<String>()
    private var initialized = false
    private var callbacksInstalled = false
    private var discoveredDevices: [String: DiscoveredDevice] = [:]
    private var sessions: [UInt64: ScannerSession] = [:]
    private var pendingSessionEvents: [UInt64: PendingSessionEvents] = [:]
    private var shutdownInProgress = false

    private init() {}

    public var discoveries: AsyncStream<DiscoveredDevice> {
        discoveryHub.makeStream()
    }

    public var discoveryFailures: AsyncStream<DiscoveryFailure> {
        discoveryFailureHub.makeStream()
    }

    public var sessionFailures: AsyncStream<SessionFailure> {
        sessionFailureHub.makeStream()
    }

    public var debugEvents: AsyncStream<String> {
        debugHub.makeStream()
    }

    public var version: String {
        guard let cString = nsdk_version() else { return "" }
        return String(cString: cString)
    }

    public func initialize() throws {
        lock.lock()
        defer { lock.unlock() }
        if initialized { return }
        if shutdownInProgress {
            throw ScannerError(code: 4, operation: "initialize blocked during shutdown")
        }
        try nsdkCheck(nsdk_initialize(), operation: "initialize")
        installCallbacksIfNeeded()
        initialized = true
    }

    public func shutdown() throws {
        lock.lock()
        if !initialized || shutdownInProgress {
            lock.unlock()
            return
        }
        shutdownInProgress = true
        initialized = false
        callbacksInstalled = false
        discoveredDevices.removeAll()
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        let oldDiscoveryHub = discoveryHub
        let oldDiscoveryFailureHub = discoveryFailureHub
        let oldSessionFailureHub = sessionFailureHub
        let oldDebugHub = debugHub
        discoveryHub = StreamHub<DiscoveredDevice>()
        discoveryFailureHub = StreamHub<DiscoveryFailure>()
        sessionFailureHub = StreamHub<SessionFailure>()
        debugHub = StreamHub<String>()
        lock.unlock()

        _ = nsdk_set_discovery_callback(nil, nil)
        _ = nsdk_set_discovery_failure_callback(nil, nil)
        _ = nsdk_set_discovered_device_callback(nil, nil)
        _ = nsdk_set_session_state_callback(nil, nil)
        _ = nsdk_set_scan_data_callback(nil, nil)
        _ = nsdk_set_session_failure_callback(nil, nil)
        _ = nsdk_set_session_init_stage_callback(nil, nil)
        _ = nsdk_set_log_callback(nil, nil)

        let shutdownCode = nsdk_shutdown()
        AppleBleRuntime.stop()
        oldDiscoveryHub.finish()
        oldDiscoveryFailureHub.finish()
        oldSessionFailureHub.finish()
        oldDebugHub.finish()

        lock.lock()
        pendingSessionEvents.removeAll()
        shutdownInProgress = false
        lock.unlock()
        try nsdkCheck(shutdownCode, operation: "shutdown")
    }

    public func startDiscovery(
        transports: Set<TransportType> = [.bleGatt],
        selectedModelId: DeviceModelId = .unknown
    ) throws {
        try ensureInitialized("startDiscovery")
        let discoverySelectedModelId: DeviceModelId = transports.contains(.bleGatt) ? selectedModelId : .unknown
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        if transports.contains(.bleGatt) {
            AppleBleRuntime.installTransport()
        }
        let mask = transports.reduce(UInt32(0)) { partial, transport in
            partial | (1 << transport.rawValue)
        }
        var request = nsdk_discovery_request_t(
            transport_mask: mask,
            selected_model_id: nsdk_device_model_id_t(rawValue: discoverySelectedModelId.rawValue)
        )
        try nsdkCheck(nsdk_start_discovery_ex(&request), operation: "startDiscovery")
    }

    public func stopDiscovery() throws {
        try ensureInitialized("stopDiscovery")
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        try nsdkCheck(nsdk_stop_discovery(), operation: "stopDiscovery")
    }

    public func connectReady(
        _ device: DiscoveredDevice,
        channelKind: ProtocolChannelKind = .scannerMaster,
        applyDecoderModule: Bool = true,
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        try await connectReady(
            deviceId: device.deviceId,
            transport: device.transportType,
            channelKind: channelKind,
            selectedModelId: device.modelId,
            applyDecoderModule: applyDecoderModule,
            timeoutMilliseconds: timeoutMilliseconds
        )
    }

    public func connectReady(
        deviceId: String,
        transport: TransportType = .bleGatt,
        channelKind: ProtocolChannelKind = .scannerMaster,
        selectedModelId: DeviceModelId = .unknown,
        applyDecoderModule: Bool = true,
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        let session = try connectSession(
            deviceId: deviceId,
            transport: transport,
            channelKind: channelKind,
            selectedModelId: selectedModelId,
            applyDecoderModule: applyDecoderModule
        )
        do {
            try await Task.detached(priority: nil) {
                try session.waitUntilReady(timeoutMilliseconds: timeoutMilliseconds)
            }.value
        } catch {
            try? session.disconnect()
            throw error
        }
        return session
    }

    private func connectSession(
        deviceId: String,
        transport: TransportType,
        channelKind: ProtocolChannelKind,
        selectedModelId: DeviceModelId,
        applyDecoderModule: Bool
    ) throws -> ScannerSession {
        try ensureInitialized("connect")
        emitDebug(
            "Connect: deviceId=\(deviceId) transport=\(transport) channelKind=\(channelKind) selectedModel=\(selectedModelId) applyDecoderModule=\(applyDecoderModule)"
        )
        if transport == .bleGatt {
            AppleBleRuntime.installTransport()
        }
        var sessionHandle: nsdk_session_handle_t = 0
        try deviceId.withCString { cDeviceID in
            var request = nsdk_connect_request_t(
                device_id: cDeviceID,
                transport: transport.cValue,
                channel_kind: channelKind.cValue,
                selected_model_id: nsdk_device_model_id_t(rawValue: selectedModelId.rawValue),
                apply_decoder_module: applyDecoderModule ? 1 : 0
            )
            try nsdkCheck(
                nsdk_connect_with_request(&request, &sessionHandle),
                operation: "connect"
            )
        }
        let session = ScannerSession(handle: sessionHandle, deviceId: deviceId, transportType: transport, sdk: self)
        var pendingEvents: PendingSessionEvents?
        lock.lock()
        sessions[sessionHandle] = session
        pendingEvents = pendingSessionEvents.removeValue(forKey: sessionHandle)
        lock.unlock()
        pendingEvents?.drain(into: session)
        return session
    }

    public func getDeviceModelProfile(_ modelId: DeviceModelId) -> DeviceModelProfile? {
        DeviceModelProfileBridge.load(modelId)
    }

    public func getDeviceModelName(_ modelId: DeviceModelId) throws -> String {
        var name = [CChar](repeating: 0, count: 64)
        try name.withUnsafeMutableBufferPointer { buffer in
            try nsdkCheck(
                nsdk_get_device_model_name(
                    nsdk_device_model_id_t(rawValue: modelId.rawValue),
                    buffer.baseAddress,
                    UInt32(buffer.count)
                ),
                operation: "getDeviceModelName"
            )
        }
        return String(cString: name)
    }

    public func getCommandDescriptor(_ command: CommandCode) throws -> CommandDescriptor {
        var descriptor = nsdk_command_descriptor_t()
        try nsdkCheck(
            nsdk_get_command_code_descriptor(command.cValue, &descriptor),
            operation: "getCommandDescriptor"
        )
        return CommandDescriptor(cValue: descriptor)
    }

    public func getBasicDeviceCommandDescriptor(_ command: BasicDeviceCommand) throws -> CommandDescriptor {
        var descriptor = nsdk_command_descriptor_t()
        try nsdkCheck(
            nsdk_get_basic_device_command_descriptor(command.cValue, &descriptor),
            operation: "getBasicDeviceCommandDescriptor"
        )
        return CommandDescriptor(cValue: descriptor)
    }

    public func getCommandCodeLabel(_ command: CommandCode) throws -> CommandCodeLabel {
        var label = nsdk_command_code_label_t()
        try nsdkCheck(
            nsdk_get_command_code_label(command.cValue, &label),
            operation: "getCommandCodeLabel"
        )
        return CommandCodeLabel(cValue: label)
    }

    public func getBasicDeviceCommandLabel(_ command: BasicDeviceCommand) throws -> BasicDeviceCommandLabel {
        var label = nsdk_basic_device_command_label_t()
        try nsdkCheck(
            nsdk_get_basic_device_command_label(command.cValue, &label),
            operation: "getBasicDeviceCommandLabel"
        )
        return BasicDeviceCommandLabel(cValue: label)
    }

    public func getDataRuleKindLabel(_ kind: DataRuleKind) throws -> DataRuleKindLabel {
        var label = nsdk_data_rule_kind_label_t()
        try nsdkCheck(
            nsdk_get_data_rule_kind_label(kind.cValue, &label),
            operation: "getDataRuleKindLabel"
        )
        return DataRuleKindLabel(cValue: label)
    }

    public func getMasterCommandDescriptor(_ command: MasterCommand) throws -> CommandDescriptor {
        var descriptor = nsdk_command_descriptor_t()
        try nsdkCheck(
            nsdk_get_master_command_descriptor(command.cValue, &descriptor),
            operation: "getMasterCommandDescriptor"
        )
        return CommandDescriptor(cValue: descriptor)
    }

    public func getMasterCommandMetadata(_ command: MasterCommand) throws -> MasterCommandMetadata {
        var metadata = nsdk_master_command_metadata_t()
        try nsdkCheck(
            nsdk_get_master_command_metadata(command.cValue, &metadata),
            operation: "getMasterCommandMetadata"
        )
        return MasterCommandMetadata(cValue: metadata)
    }

    public func getMasterCommandLabel(_ command: MasterCommand) throws -> MasterCommandLabel {
        var label = nsdk_master_command_label_t()
        try nsdkCheck(
            nsdk_get_master_command_label(command.cValue, &label),
            operation: "getMasterCommandLabel"
        )
        return MasterCommandLabel(cValue: label)
    }

    public func getMasterCommandCategoryLabel(_ category: MasterCommandCategory) throws -> MasterCommandCategoryLabel {
        var label = nsdk_master_command_category_label_t()
        try nsdkCheck(
            nsdk_get_master_command_category_label(category.cValue, &label),
            operation: "getMasterCommandCategoryLabel"
        )
        return MasterCommandCategoryLabel(cValue: label)
    }

    public func getMasterCommandSectionLabel(_ section: MasterCommandSection) throws -> MasterCommandSectionLabel {
        var label = nsdk_master_command_section_label_t()
        try nsdkCheck(
            nsdk_get_master_command_section_label(section.cValue, &label),
            operation: "getMasterCommandSectionLabel"
        )
        return MasterCommandSectionLabel(cValue: label)
    }

    public func isModuleCommandDangerous(_ kind: ModuleCommandKind) throws -> Bool {
        var dangerous: Int32 = 0
        try nsdkCheck(
            nsdk_is_module_command_dangerous(kind.cValue, &dangerous),
            operation: "isModuleCommandDangerous"
        )
        return dangerous != 0
    }

    public func getModuleCommandKindLabel(_ kind: ModuleCommandKind) throws -> ModuleCommandKindLabel {
        var label = nsdk_module_command_kind_label_t()
        try nsdkCheck(
            nsdk_get_module_command_kind_label(kind.cValue, &label),
            operation: "getModuleCommandKindLabel"
        )
        return ModuleCommandKindLabel(cValue: label)
    }

    public func getModuleActionPresetLabel(actionID: String) throws -> ModuleActionPresetLabel? {
        var label = nsdk_module_action_preset_label_t()
        var supported: Int32 = 0
        try actionID.withCString { cActionID in
            try nsdkCheck(
                nsdk_get_module_action_preset_label(cActionID, &label, &supported),
                operation: "getModuleActionPresetLabel"
            )
        }
        return supported != 0 ? ModuleActionPresetLabel(cValue: label) : nil
    }

    public func getModuleTestRecommendations(family: ModuleFamily) throws -> [ModuleTestRecommendation] {
        guard family != .unknown else {
            return []
        }
        let count = nsdk_module_test_recommendation_count(family.cValue)
        guard count > 0 else {
            return []
        }
        var recommendations: [ModuleTestRecommendation] = []
        recommendations.reserveCapacity(Int(count))
        for index in 0..<count {
            var recommendation = nsdk_module_test_recommendation_t()
            try nsdkCheck(
                nsdk_module_test_recommendation_get_at(family.cValue, index, &recommendation),
                operation: "getModuleTestRecommendations"
            )
            recommendations.append(ModuleTestRecommendation(cValue: recommendation))
        }
        return recommendations
    }

    public func getNt212xParameterDefinitions() throws -> [Nt212xParameterDefinition] {
        try loadNativeDefinitions(count: nsdk_nt212x_parameter_count()) { index in
            var metadata = nsdk_nt212x_parameter_metadata_t()
            try nsdkCheck(
                nsdk_nt212x_parameter_get_at(index, &metadata),
                operation: "getNt212xParameterDefinitions"
            )
            return Nt212xParameterDefinition(cValue: metadata)
        }
    }

    public func findNt212xParameter(byID parameterID: UInt16) throws -> Nt212xParameterDefinition? {
        var metadata = nsdk_nt212x_parameter_metadata_t()
        return try nsdkLookupOrNil(
            nsdk_nt212x_parameter_find_by_id(parameterID, &metadata),
            operation: "findNt212xParameter"
        ) {
            Nt212xParameterDefinition(cValue: metadata)
        }
    }

    public func findNt212xParameter(key: String) throws -> Nt212xParameterDefinition? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findNt212xParameter requires non-empty key")
        }
        var metadata = nsdk_nt212x_parameter_metadata_t()
        return try key.withCString { cKey in
            try nsdkLookupOrNil(
                nsdk_nt212x_parameter_find_by_key(cKey, &metadata),
                operation: "findNt212xParameter"
            ) {
                Nt212xParameterDefinition(cValue: metadata)
            }
        }
    }

    public func getNt280hParameterDefinitions() throws -> [Nt280hParameterDefinition] {
        try loadNativeDefinitions(count: nsdk_nt280h_parameter_count()) { index in
            var metadata = nsdk_nt280h_parameter_metadata_t()
            try nsdkCheck(
                nsdk_nt280h_parameter_get_at(index, &metadata),
                operation: "getNt280hParameterDefinitions"
            )
            return Nt280hParameterDefinition(cValue: metadata)
        }
    }

    public func findNt280hParameter(byID parameterID: UInt16) throws -> Nt280hParameterDefinition? {
        var metadata = nsdk_nt280h_parameter_metadata_t()
        return try nsdkLookupOrNil(
            nsdk_nt280h_parameter_find_by_id(parameterID, &metadata),
            operation: "findNt280hParameter"
        ) {
            Nt280hParameterDefinition(cValue: metadata)
        }
    }

    public func findNt280hParameter(key: String) throws -> Nt280hParameterDefinition? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findNt280hParameter requires non-empty key")
        }
        var metadata = nsdk_nt280h_parameter_metadata_t()
        return try key.withCString { cKey in
            try nsdkLookupOrNil(
                nsdk_nt280h_parameter_find_by_key(cKey, &metadata),
                operation: "findNt280hParameter"
            ) {
                Nt280hParameterDefinition(cValue: metadata)
            }
        }
    }

    public func getSe4750ParameterDefinitions() throws -> [Se4750ParameterDefinition] {
        try loadNativeDefinitions(count: nsdk_se4750_parameter_count()) { index in
            var metadata = nsdk_se4750_parameter_metadata_t()
            try nsdkCheck(
                nsdk_se4750_parameter_get_at(index, &metadata),
                operation: "getSe4750ParameterDefinitions"
            )
            return Se4750ParameterDefinition(cValue: metadata)
        }
    }

    public func findSe4750Parameter(byID parameterID: UInt32) throws -> Se4750ParameterDefinition? {
        var metadata = nsdk_se4750_parameter_metadata_t()
        return try nsdkLookupOrNil(
            nsdk_se4750_parameter_find_by_id(parameterID, &metadata),
            operation: "findSe4750Parameter"
        ) {
            Se4750ParameterDefinition(cValue: metadata)
        }
    }

    public func findSe4750Parameter(key: String) throws -> Se4750ParameterDefinition? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findSe4750Parameter requires non-empty key")
        }
        var metadata = nsdk_se4750_parameter_metadata_t()
        return try key.withCString { cKey in
            try nsdkLookupOrNil(
                nsdk_se4750_parameter_find_by_key(cKey, &metadata),
                operation: "findSe4750Parameter"
            ) {
                Se4750ParameterDefinition(cValue: metadata)
            }
        }
    }

    public func getNtc06hSettingDefinitions() throws -> [Ntc06hSettingDefinition] {
        try loadNativeDefinitions(count: nsdk_ntc06h_setting_count()) { index in
            var metadata = nsdk_ntc06h_setting_metadata_t()
            try nsdkCheck(
                nsdk_ntc06h_setting_get_at(index, &metadata),
                operation: "getNtc06hSettingDefinitions"
            )
            return Ntc06hSettingDefinition(cValue: metadata)
        }
    }

    public func findNtc06hSetting(key: String) throws -> Ntc06hSettingDefinition? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findNtc06hSetting requires non-empty key")
        }
        var metadata = nsdk_ntc06h_setting_metadata_t()
        return try key.withCString { cKey in
            try nsdkLookupOrNil(
                nsdk_ntc06h_setting_find_by_key(cKey, &metadata),
                operation: "findNtc06hSetting"
            ) {
                Ntc06hSettingDefinition(cValue: metadata)
            }
        }
    }

    public func findNtc06hSetting(settingCode: String) throws -> Ntc06hSettingDefinition? {
        guard !settingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findNtc06hSetting requires non-empty settingCode")
        }
        var metadata = nsdk_ntc06h_setting_metadata_t()
        return try settingCode.withCString { cSettingCode in
            try nsdkLookupOrNil(
                nsdk_ntc06h_setting_find_by_code(cSettingCode, &metadata),
                operation: "findNtc06hSetting"
            ) {
                Ntc06hSettingDefinition(cValue: metadata)
            }
        }
    }

    public func getModuleParameterQuickValues(
        family: ModuleFamily,
        parameterID: UInt32
    ) throws -> [ModuleParameterQuickValue] {
        guard family != .unknown else {
            return []
        }

        let count = nsdk_module_parameter_quick_value_count(family.cValue, parameterID)
        guard count > 0 else {
            return []
        }

        var quickValues: [ModuleParameterQuickValue] = []
        quickValues.reserveCapacity(Int(count))
        for index in 0..<count {
            var value = nsdk_module_parameter_quick_value_t()
            try nsdkCheck(
                nsdk_module_parameter_quick_value_get_at(family.cValue, parameterID, index, &value),
                operation: "getModuleParameterQuickValues"
            )
            quickValues.append(ModuleParameterQuickValue(cValue: value))
        }
        return quickValues
    }

    public func getModuleParameterNumericInputSpec(
        family: ModuleFamily,
        parameterID: UInt32
    ) throws -> ModuleParameterNumericInputSpec? {
        guard family != .unknown else {
            return nil
        }

        var spec = nsdk_module_parameter_numeric_input_spec_t()
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_get_module_parameter_numeric_input_spec(family.cValue, parameterID, &spec, &supported),
            operation: "getModuleParameterNumericInputSpec"
        )
        return supported != 0 ? ModuleParameterNumericInputSpec(cValue: spec) : nil
    }

    public func getModuleParameterBooleanPayloadPair(
        family: ModuleFamily,
        parameterID: UInt32
    ) throws -> ModuleParameterBooleanPayloadPair? {
        guard family != .unknown else {
            return nil
        }

        var pair = nsdk_module_parameter_boolean_payload_pair_t()
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_get_module_parameter_boolean_payload_pair(family.cValue, parameterID, &pair, &supported),
            operation: "getModuleParameterBooleanPayloadPair"
        )
        return supported != 0 ? ModuleParameterBooleanPayloadPair(cValue: pair) : nil
    }

    public func getModuleParameterEnumLabel(
        family: ModuleFamily,
        parameterID: UInt32,
        rawLabel: String
    ) throws -> ModuleParameterEnumLabel? {
        guard family != .unknown else {
            return nil
        }

        var label = nsdk_module_parameter_enum_label_t()
        var supported: Int32 = 0
        try rawLabel.withCString { cRawLabel in
            try nsdkCheck(
                nsdk_get_module_parameter_enum_label(family.cValue, parameterID, cRawLabel, &label, &supported),
                operation: "getModuleParameterEnumLabel"
            )
        }
        return supported != 0 ? ModuleParameterEnumLabel(cValue: label) : nil
    }

    public func getModuleParameterTitleLabel(
        family: ModuleFamily,
        parameterID: UInt32,
        aliasName: String,
        displayName: String
    ) throws -> ModuleParameterTitleLabel? {
        guard family != .unknown else {
            return nil
        }

        var label = nsdk_module_parameter_title_label_t()
        var supported: Int32 = 0
        try aliasName.withCString { cAliasName in
            try displayName.withCString { cDisplayName in
                try nsdkCheck(
                    nsdk_get_module_parameter_title_label(
                        family.cValue,
                        parameterID,
                        cAliasName,
                        cDisplayName,
                        &label,
                        &supported
                    ),
                    operation: "getModuleParameterTitleLabel"
                )
            }
        }
        return supported != 0 ? ModuleParameterTitleLabel(cValue: label) : nil
    }

    public func getModuleParameterKindLabel(_ kind: ModuleParameterKind) throws -> ModuleParameterKindLabel? {
        var label = nsdk_module_parameter_kind_label_t()
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_get_module_parameter_kind_label(kind.cValue, &label, &supported),
            operation: "getModuleParameterKindLabel"
        )
        return supported != 0 ? ModuleParameterKindLabel(cValue: label) : nil
    }

    public func getModuleTaxonomyEntries(kind: ModuleTaxonomyKind) throws -> [ModuleTaxonomyEntry] {
        let count = nsdk_module_taxonomy_entry_count(kind.cValue)
        guard count > 0 else {
            return []
        }

        var entries: [ModuleTaxonomyEntry] = []
        entries.reserveCapacity(Int(count))
        for index in 0..<count {
            var entry = nsdk_module_taxonomy_entry_t()
            try nsdkCheck(
                nsdk_module_taxonomy_entry_get_at(kind.cValue, index, &entry),
                operation: "getModuleTaxonomyEntries"
            )
            entries.append(ModuleTaxonomyEntry(cValue: entry))
        }
        return entries
    }

    internal func removeSession(handle: UInt64) {
        lock.lock()
        sessions.removeValue(forKey: handle)
        lock.unlock()
    }

    internal func emitDebug(_ message: String) {
        debugHub.yield(message)
    }

    internal func onDiscoveryFailure(_ failure: DiscoveryFailure) {
        discoveryFailureHub.yield(failure)
    }

    internal func findSession(handle: UInt64) -> ScannerSession? {
        lock.lock()
        defer { lock.unlock() }
        return sessions[handle]
    }

    private func ensureInitialized(_ operation: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard initialized else {
            throw ScannerError(code: -1, operation: "\(operation) requires initialize() first")
        }
    }

    private func installCallbacksIfNeeded() {
        guard !callbacksInstalled else { return }
        let userData = Unmanaged.passUnretained(self).toOpaque()
        _ = nsdk_set_discovery_callback(nsdk_swift_discovery_callback, userData)
        _ = nsdk_set_discovery_failure_callback(nsdk_swift_discovery_failure_callback, userData)
        _ = nsdk_set_discovered_device_callback(nsdk_swift_discovered_device_callback, userData)
        _ = nsdk_set_session_state_callback(nsdk_swift_state_callback, userData)
        _ = nsdk_set_scan_data_callback(nsdk_swift_scan_callback, userData)
        _ = nsdk_set_session_failure_callback(nsdk_swift_session_failure_callback, userData)
        _ = nsdk_set_session_init_stage_callback(nsdk_swift_session_initialization_stage_callback, userData)
        _ = nsdk_set_log_callback(nsdk_swift_log_callback, userData)
        callbacksInstalled = true
    }

    fileprivate func handleDiscovery(deviceID: String, name: String, transport: TransportType) {
        handleDiscovery(deviceID: deviceID, name: name, transport: transport, modelId: .unknown, matchReason: nil)
    }

    fileprivate func handleDiscovery(
        deviceID: String,
        name: String,
        transport: TransportType,
        modelId: DeviceModelId,
        matchReason: String?
    ) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if transport == .bleGatt && normalizedName.isEmpty {
            emitDebug("Drop unnamed BLE discovery deviceId=\(deviceID) model=\(modelId) reason=\(matchReason ?? "unknown")")
            return
        }
        let device = DiscoveredDevice(
            deviceId: deviceID,
            name: normalizedName,
            transportType: transport,
            modelId: modelId,
            matchReason: matchReason,
            rssi: nil
        )
        let shouldYield: Bool
        lock.lock()
        if let existing = discoveredDevices[deviceID] {
            let nameImproved = existing.name.isEmpty && !device.name.isEmpty
            let nameChanged = !device.name.isEmpty && existing.name != device.name
            let modelChanged = existing.modelId != device.modelId
            let matchReasonChanged = existing.matchReason != device.matchReason
            shouldYield = nameImproved || nameChanged || modelChanged || matchReasonChanged
        } else {
            shouldYield = true
        }
        if shouldYield {
            discoveredDevices[deviceID] = device
        }
        lock.unlock()
        if shouldYield {
            discoveryHub.yield(device)
        }
    }

    fileprivate func handleState(handle: UInt64, state: SessionState) {
        if let session = findSession(handle: handle) {
            session.onStateChanged(state)
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(.state(state))
        lock.unlock()
    }

    fileprivate func handleScan(handle: UInt64, scanData: nsdk_scan_data_t) {
        var mutableScanData = scanData
        let textBytes = (try? copyBytes(
            expectedLength: mutableScanData.text_size,
            copy: { buffer, capacity, outLength in
                nsdk_scan_data_copy_text_bytes(&mutableScanData, buffer, capacity, outLength)
            },
            operation: "scanData.copyTextBytes"
        )) ?? Data()
        let rawBytes = (try? copyBytes(
            expectedLength: mutableScanData.raw_size,
            copy: { buffer, capacity, outLength in
                nsdk_scan_data_copy_raw_bytes(&mutableScanData, buffer, capacity, outLength)
            },
            operation: "scanData.copyRawBytes"
        )) ?? Data()
        if let session = findSession(handle: handle) {
            session.onScanEvent(
                timestampMs: mutableScanData.timestamp_ms,
                barcodeType: mutableScanData.barcode_type,
                textBytes: textBytes,
                rawBytes: rawBytes
            )
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(
            .scan(
                PendingScanEvent(
                    timestampMs: mutableScanData.timestamp_ms,
                    barcodeType: mutableScanData.barcode_type,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            )
        )
        lock.unlock()
    }

    fileprivate static func describeTransportFailure(
        transport: TransportType,
        code: TransportFailureCode
    ) -> String {
        switch transport {
        case .bleGatt:
            switch code {
            case .serviceDiscoveryStartFailed: return "BLE session failed: service discovery could not start"
            case .serviceDiscoveryFailed: return "BLE session failed: service discovery failed"
            case .notifyServiceMissing: return "BLE session failed: notify service missing"
            case .notifyCharacteristicMissing: return "BLE session failed: notify characteristic missing"
            case .setNotificationFailed: return "BLE session failed: enabling notifications failed"
            case .notifyDescriptorMissing: return "BLE session failed: notify descriptor missing"
            case .notifyDescriptorWriteFailed: return "BLE session failed: notify descriptor write failed"
            case .connectionTimeout: return "BLE session failed: connection timed out"
            case .gattFailure: return "BLE session failed: platform GATT failure"
            case .platformStatusError: return "BLE session failed: platform connection status error"
            case .unknown: return "BLE session failed: unknown transport error"
            }
        case .usbHid:
            return code == .platformStatusError
                ? "UsbHid session failed: platform transport status error"
                : "UsbHid session failed: transport error"
        case .usbSerial:
            return code == .platformStatusError
                ? "UsbSerial session failed: platform transport status error"
                : "UsbSerial session failed: transport error"
        case .sppClassic:
            return code == .platformStatusError
                ? "SppClassic session failed: platform transport status error"
                : "SppClassic session failed: transport error"
        }
    }
}

extension ScannerSDK {
    internal static func makeTestingInstance() -> ScannerSDK {
        ScannerSDK()
    }

    internal func makeTestingSession(
        handle: UInt64,
        deviceId: String = "",
        transportType: TransportType = .bleGatt
    ) -> ScannerSession {
        ScannerSession(handle: handle, deviceId: deviceId, transportType: transportType, sdk: self)
    }

    internal func registerSessionForTesting(_ session: ScannerSession) -> ScannerSession {
        var pendingEvents: PendingSessionEvents?
        lock.lock()
        sessions[session.handle] = session
        pendingEvents = pendingSessionEvents.removeValue(forKey: session.handle)
        lock.unlock()
        pendingEvents?.drain(into: session)
        return session
    }

    internal func registerSessionForTesting(handle: UInt64) -> ScannerSession {
        registerSessionForTesting(makeTestingSession(handle: handle))
    }

    internal func resetSessionsForTesting() {
        lock.lock()
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        lock.unlock()
    }

    internal func simulatePendingState(_ state: SessionState, handle: UInt64) {
        handleState(handle: handle, state: state)
    }

    internal func simulatePendingFailure(
        handle: UInt64,
        transport: TransportType,
        code: TransportFailureCode,
        platformErrorCode: Int32
    ) {
        var failure = nsdk_session_failure_t()
        failure.transport = transport.cValue
        failure.code = nsdk_transport_failure_code_t(rawValue: code.rawValue)
        failure.ble_issue = nsdk_ble_transport_issue_t(rawValue: code.rawValue)
        failure.platform_error = platformErrorCode
        handleSessionFailure(handle: handle, failure: failure)
    }

    internal func simulatePendingScan(
        handle: UInt64,
        timestampMs: UInt64,
        barcodeType: Int32,
        textBytes: Data,
        rawBytes: Data
    ) {
        if let session = findSession(handle: handle) {
            session.onScanEvent(
                timestampMs: timestampMs,
                barcodeType: barcodeType,
                textBytes: textBytes,
                rawBytes: rawBytes
            )
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(
            .scan(
                PendingScanEvent(
                    timestampMs: timestampMs,
                    barcodeType: barcodeType,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            )
        )
        lock.unlock()
    }

    internal func simulatePendingInitializationStage(
        handle: UInt64,
        selectedModelId: DeviceModelId,
        stage: SessionInitializationStage,
        timestampMs: UInt64,
        traceId: UInt64,
        success: Bool,
        errorCode: Int32,
        message: String?
    ) {
        if let session = findSession(handle: handle) {
            session.onInitializationStage(
                SessionInitializationStageEvent(
                    sessionHandle: handle,
                    deviceId: session.deviceId,
                    selectedModelId: selectedModelId,
                    stage: stage,
                    timestampMs: timestampMs,
                    traceId: traceId,
                    success: success,
                    errorCode: errorCode,
                    message: message
                )
            )
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelId: selectedModelId,
                    stage: stage,
                    timestampMs: timestampMs,
                    traceId: traceId,
                    success: success,
                    errorCode: errorCode,
                    message: message
                )
            )
        )
        lock.unlock()
    }

    fileprivate func handleSessionFailure(handle: UInt64, failure: nsdk_session_failure_t) {
        let transport = TransportType(rawValue: failure.transport.rawValue) ?? .bleGatt
        let code = TransportFailureCode(rawValue: failure.code.rawValue) ?? .unknown
        let bleTransportIssue = transport == .bleGatt
            ? BleTransportIssue(rawValue: failure.ble_issue.rawValue).flatMap { $0 == .unknown ? nil : $0 }
            : nil
        let activeSession = findSession(handle: handle)
        let sessionFailure = SessionFailure(
            sessionHandle: handle,
            deviceId: activeSession?.deviceId ?? "",
            transportType: transport,
            code: code,
            message: ScannerSDK.describeTransportFailure(transport: transport, code: code),
            bleTransportIssue: bleTransportIssue,
            platformErrorCode: failure.platform_error
        )
        sessionFailureHub.yield(sessionFailure)
        if let session = activeSession {
            session.onFailure(sessionFailure)
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(
            .failure(
                PendingSessionFailure(
                    transport: transport,
                    code: code,
                    bleTransportIssue: bleTransportIssue,
                    platformErrorCode: failure.platform_error
                )
            )
        )
        lock.unlock()
    }

    fileprivate func handleSessionInitializationStage(handle: UInt64, event: nsdk_session_init_stage_event_t) {
        let stageEvent = SessionInitializationStageEvent(
            sessionHandle: handle,
            deviceId: findSession(handle: handle)?.deviceId ?? "",
            selectedModelId: DeviceModelId(rawValue: event.selected_model_id.rawValue) ?? .unknown,
            stage: SessionInitializationStage(cValue: event.stage),
            timestampMs: event.timestamp_ms,
            traceId: event.trace_id,
            success: event.success != 0,
            errorCode: event.error_code,
            message: stringFromCStringBuffer(event.message).isEmpty ? nil : stringFromCStringBuffer(event.message)
        )
        if let session = findSession(handle: handle) {
            session.onInitializationStage(stageEvent)
            return
        }
        lock.lock()
        pendingSessionEvents[handle, default: PendingSessionEvents()].events.append(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelId: stageEvent.selectedModelId,
                    stage: stageEvent.stage,
                    timestampMs: stageEvent.timestampMs,
                    traceId: stageEvent.traceId,
                    success: stageEvent.success,
                    errorCode: stageEvent.errorCode,
                    message: stageEvent.message
                )
            )
        )
        lock.unlock()
    }

    fileprivate func handleNativeLog(level: Int32, message: String) {
        let prefix = level >= 3 ? "core-error:" : "core:"
        emitDebug("\(prefix) \(message)")
    }
}

private struct PendingScanEvent {
    let timestampMs: UInt64
    let barcodeType: Int32
    let textBytes: Data
    let rawBytes: Data
}

private struct PendingSessionFailure {
    let transport: TransportType
    let code: TransportFailureCode
    let bleTransportIssue: BleTransportIssue?
    let platformErrorCode: Int32
}

private struct PendingSessionInitializationStage {
    let selectedModelId: DeviceModelId
    let stage: SessionInitializationStage
    let timestampMs: UInt64
    let traceId: UInt64
    let success: Bool
    let errorCode: Int32
    let message: String?
}

private enum PendingSessionEvent {
    case state(SessionState)
    case scan(PendingScanEvent)
    case failure(PendingSessionFailure)
    case initializationStage(PendingSessionInitializationStage)
}

private struct PendingSessionEvents {
    var events: [PendingSessionEvent] = []

    mutating func drain(into session: ScannerSession) {
        for event in events {
            switch event {
            case .state(let state):
                session.onStateChanged(state)
            case .scan(let scan):
                session.onScanEvent(
                    timestampMs: scan.timestampMs,
                    barcodeType: scan.barcodeType,
                    textBytes: scan.textBytes,
                    rawBytes: scan.rawBytes
                )
            case .failure(let failure):
                session.onFailure(
                    SessionFailure(
                        sessionHandle: session.handle,
                        deviceId: session.deviceId,
                        transportType: failure.transport,
                        code: failure.code,
                        message: ScannerSDK.describeTransportFailure(transport: failure.transport, code: failure.code),
                        bleTransportIssue: failure.bleTransportIssue,
                        platformErrorCode: failure.platformErrorCode
                    )
                )
            case .initializationStage(let stage):
                session.onInitializationStage(
                    SessionInitializationStageEvent(
                        sessionHandle: session.handle,
                        deviceId: session.deviceId,
                        selectedModelId: stage.selectedModelId,
                        stage: stage.stage,
                        timestampMs: stage.timestampMs,
                        traceId: stage.traceId,
                        success: stage.success,
                        errorCode: stage.errorCode,
                        message: stage.message
                    )
                )
            }
        }
        events.removeAll()
    }
}

private func nsdk_swift_discovery_callback(
    deviceID: UnsafePointer<CChar>?,
    name: UnsafePointer<CChar>?,
    transport: nsdk_transport_type_t,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleDiscovery(
        deviceID: deviceID.map(String.init(cString:)) ?? "",
        name: name.map(String.init(cString:)) ?? "",
        transport: TransportType(rawValue: transport.rawValue) ?? .bleGatt
    )
}

private func nsdk_swift_discovery_failure_callback(
    failure: UnsafePointer<nsdk_discovery_failure_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let failure else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.onDiscoveryFailure(DiscoveryFailure(cValue: failure.pointee))
}

private func nsdk_swift_discovered_device_callback(
    device: UnsafePointer<nsdk_discovered_device_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let device else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    let value = device.pointee
    let matchReason = stringFromCStringBuffer(value.match_reason)
    sdk.handleDiscovery(
        deviceID: stringFromCStringBuffer(value.device_id),
        name: stringFromCStringBuffer(value.name),
        transport: TransportType(rawValue: value.transport.rawValue) ?? .bleGatt,
        modelId: DeviceModelId(rawValue: value.model_id.rawValue) ?? .unknown,
        matchReason: matchReason.isEmpty ? nil : matchReason
    )
}

private func nsdk_swift_state_callback(
    session: nsdk_session_handle_t,
    state: nsdk_session_state_t,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleState(handle: session, state: SessionState(cValue: state))
}

private func nsdk_swift_scan_callback(
    session: nsdk_session_handle_t,
    scanData: UnsafePointer<nsdk_scan_data_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let scanData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleScan(handle: session, scanData: scanData.pointee)
}

private func nsdk_swift_session_failure_callback(
    session: nsdk_session_handle_t,
    failure: UnsafePointer<nsdk_session_failure_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let failure else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleSessionFailure(handle: session, failure: failure.pointee)
}

private func nsdk_swift_session_initialization_stage_callback(
    session: nsdk_session_handle_t,
    event: UnsafePointer<nsdk_session_init_stage_event_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let event else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleSessionInitializationStage(handle: session, event: event.pointee)
}

private func nsdk_swift_log_callback(
    level: Int32,
    message: UnsafePointer<CChar>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleNativeLog(level: level, message: message.map(String.init(cString:)) ?? "")
}
