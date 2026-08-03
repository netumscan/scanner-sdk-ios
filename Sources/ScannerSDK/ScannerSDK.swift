import Foundation
import CNSDK

public final class ScannerSDK: @unchecked Sendable {
    public static let shared = ScannerSDK()
    private static let requiredNativeAbiVersion: UInt32 = 0x010000

    private let lock = NSLock()
    private let abiLock = NSLock()
    private var discoveryHub = StreamHub<DiscoveredDevice>()
    private var discoveryFailureHub = StreamHub<DiscoveryFailure>()
    private var sessionFailureHub = StreamHub<SessionFailure>()
    private var commandTraceHub = StreamHub<CommandTrace>()
    private var debugHub = StreamHub<String>()
    private var initialized = false
    private var callbacksInstalled = false
    private var discoveredDevices: [String: DiscoveredDevice] = [:]
    private var sessions: [UInt64: ScannerSession] = [:]
    private var pendingSessionEvents: [UInt64: PendingSessionEvents] = [:]
    private var retiredSessionHandles = Set<UInt64>()
    private var retiredSessionHandleOrder: [UInt64] = []
    private var shutdownInProgress = false
    private let diagnosticsRecorder = DiagnosticsRecorder()
    private var cachedLocalizationEntries: [SdkLocalizationEntry]?
    private var cachedLocalizationIndex: [String: [String: String]]?
    private var nativeAbiValidated = false
    private var nativeAbiValidationError: ScannerError?
    private var lastLocalizationCatalogError: ScannerError?

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

    public var commandTraces: AsyncStream<CommandTrace> {
        commandTraceHub.makeStream()
    }

    public var debugEvents: AsyncStream<String> {
        debugHub.makeStream()
    }

    public var version: String {
        guard let cString = nsdk_version() else { return "" }
        return String(cString: cString)
    }

    /// The most recent error encountered by the non-throwing catalog resolver.
    public var localizationCatalogError: ScannerError? {
        lock.lock()
        defer { lock.unlock() }
        return lastLocalizationCatalogError
    }

    public func localizationEntries() throws -> [SdkLocalizationEntry] {
        lock.lock()
        if let entries = cachedLocalizationEntries {
            lock.unlock()
            return entries
        }
        lock.unlock()

        try ensureNativeAbiCompatible()
        var count: UInt32 = 0
        try nsdkCheck(nsdk_localization_entry_count(&count), operation: "localizationEntries")
        let entries = try loadNativeDefinitions(count: count) { index in
            var entry = makeNsdkLocalizationEntry()
            try nsdkCheck(
                nsdk_localization_entry_get_at(index, &entry),
                operation: "localizationEntries"
            )
            return SdkLocalizationEntry(cValue: entry)
        }

        lock.lock()
        if cachedLocalizationEntries == nil {
            cachedLocalizationEntries = entries
            cachedLocalizationIndex = Self.makeLocalizationIndex(entries)
        }
        lastLocalizationCatalogError = nil
        let result = cachedLocalizationEntries ?? entries
        lock.unlock()
        return result
    }

    public var supportedLocales: [String] {
        (loadLocalizationEntriesForResolution() ?? [])
            .map(\.locale)
            .reduce(into: Set<String>()) { $0.insert($1) }
            .sorted()
    }

    public func localize(
        _ localizationKey: String,
        fallbackDisplayName: String = "",
        locale: Locale = .current
    ) -> String {
        _ = loadLocalizationEntriesForResolution()
        lock.lock()
        let catalog = cachedLocalizationIndex ?? [:]
        lock.unlock()
        return Self.resolveLocalization(
            catalog,
            localizationKey: localizationKey,
            fallbackDisplayName: fallbackDisplayName,
            locale: locale
        )
    }

    public func localize(_ label: CapabilityLabel, locale: Locale = .current) -> String {
        localize(label.localizationKey, fallbackDisplayName: label.displayName, locale: locale)
    }

    public func localize(_ domain: CapabilityDomain, locale: Locale = .current) -> String {
        localize(domain.localizationKey, fallbackDisplayName: domain.displayName, locale: locale)
    }

    internal static func resolveLocalization(
        _ catalog: [String: [String: String]],
        localizationKey: String,
        fallbackDisplayName: String,
        locale: Locale
    ) -> String {
        let translations = catalog[localizationKey] ?? [:]
        for candidate in localeCandidates(locale) {
            if let text = translations[candidate] {
                return text
            }
        }
        return fallbackDisplayName.isEmpty ? localizationKey : fallbackDisplayName
    }

    private func loadLocalizationEntriesForResolution() -> [SdkLocalizationEntry]? {
        do {
            return try localizationEntries()
        } catch let error as ScannerError {
            recordLocalizationCatalogError(error)
        } catch {
            recordLocalizationCatalogError(ScannerError(code: -1, operation: "localization catalog: \(error)"))
        }
        return nil
    }

    private func recordLocalizationCatalogError(_ error: ScannerError) {
        lock.lock()
        lastLocalizationCatalogError = error
        lock.unlock()
        emitDebug("localization catalog error: \(error)")
    }

    internal static func localeCandidates(_ locale: Locale) -> [String] {
        let tag = normalizeLocaleTag(locale.identifier)
        let language = locale.languageCode?.lowercased() ?? "en"
        var candidates = [tag]
        if language == "zh" {
            let script = locale.scriptCode
            let region = locale.regionCode?.uppercased() ?? ""
            if script?.caseInsensitiveCompare("Hans") == .orderedSame ||
                (script == nil && (region.isEmpty || region == "CN" || region == "SG")) {
                candidates.append("zh-Hans")
            }
        }
        let baseParts = tag.split(separator: "-").prefix { $0.count != 1 }.map(String.init)
        for count in stride(from: baseParts.count, through: 1, by: -1) {
            candidates.append(baseParts.prefix(count).joined(separator: "-"))
        }
        candidates.append(language.isEmpty ? "en" : language)
        candidates.append("en")
        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private static func normalizeLocaleTag(_ value: String) -> String {
        let bcp47 = value.replacingOccurrences(of: "_", with: "-")
            .split(separator: "@", maxSplits: 1)
            .first.map(String.init) ?? value
        let parts = bcp47.split(separator: "-")
            .map(String.init)
        guard let language = parts.first else { return "en" }
        return ([language.lowercased()] + parts.dropFirst().map { part in
            part.count == 4 ? part.lowercased().capitalized : part.uppercased()
        }).joined(separator: "-")
    }

    private static func makeLocalizationIndex(_ entries: [SdkLocalizationEntry]) -> [String: [String: String]] {
        Dictionary(grouping: entries, by: \.key).mapValues { values in
            Dictionary(uniqueKeysWithValues: values.map { (normalizeLocaleTag($0.locale), $0.text) })
        }
    }

    public func exportNativeLogs(_ request: LogExportRequest = LogExportRequest()) throws -> LogPackage {
        lock.lock()
        let activeSession = sessions.values.first
        lock.unlock()
        return try diagnosticsRecorder.export(
            request: request,
            context: DiagnosticsExportContext(
                platform: "ios",
                bridgeVersion: "swift-wrapper",
                sdkVersion: version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "local-dev" : version,
                activeDeviceId: activeSession?.deviceId,
                activeSelectedModelId: nil,
                activeSessionState: activeSession.map { "\($0.latestState)" }
            )
        )
    }

    public func initialize() throws {
        lock.lock()
        defer { lock.unlock() }
        if initialized { return }
        if shutdownInProgress {
            throw ScannerError(code: 4, operation: "initialize blocked during shutdown")
        }
        try ensureNativeAbiCompatible()
        try nsdkCheck(nsdk_initialize(), operation: "initialize")
        try installCallbacksIfNeeded()
        initialized = true
    }

    private func ensureNativeAbiCompatible() throws {
        abiLock.lock()
        defer { abiLock.unlock() }
        if nativeAbiValidated {
            return
        }
        if let error = nativeAbiValidationError {
            throw error
        }
        if nsdk_abi_is_compatible(Self.requiredNativeAbiVersion) != 0 {
            nativeAbiValidated = true
            return
        }
        let actualAbi = nsdk_abi_version()
        let error = ScannerError(
            code: -1,
            operation: "native ABI mismatch required=0x\(String(Self.requiredNativeAbiVersion, radix: 16)) actual=0x\(String(actualAbi, radix: 16))"
        )
        nativeAbiValidationError = error
        throw error
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
        let activeSessions = Array(sessions.values)
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        retiredSessionHandles.removeAll()
        retiredSessionHandleOrder.removeAll()
        let oldDiscoveryHub = discoveryHub
        let oldDiscoveryFailureHub = discoveryFailureHub
        let oldSessionFailureHub = sessionFailureHub
        let oldCommandTraceHub = commandTraceHub
        let oldDebugHub = debugHub
        discoveryHub = StreamHub<DiscoveredDevice>()
        discoveryFailureHub = StreamHub<DiscoveryFailure>()
        sessionFailureHub = StreamHub<SessionFailure>()
        commandTraceHub = StreamHub<CommandTrace>()
        debugHub = StreamHub<String>()
        lock.unlock()

        for session in activeSessions {
            session.terminateForSdkShutdown()
        }

        _ = nsdk_set_callbacks(nil)

        let shutdownCode = nsdk_shutdown()
        AppleBleRuntime.stop()
        oldDiscoveryHub.finish()
        oldDiscoveryFailureHub.finish()
        oldSessionFailureHub.finish()
        oldCommandTraceHub.finish()
        oldDebugHub.finish()

        lock.lock()
        pendingSessionEvents.removeAll()
        shutdownInProgress = false
        lock.unlock()
        try nsdkCheck(shutdownCode, operation: "shutdown")
    }

    public func startDiscovery(
        transports: Set<TransportType> = [.bleGatt],
        selectedModelKey: String = ""
    ) throws {
        try ensureInitialized("startDiscovery")
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        if transports.contains(.bleGatt) {
            AppleBleRuntime.installTransport()
        }
        let mask = transports.reduce(UInt32(0)) { partial, transport in
            partial | (1 << UInt32(transport.rawValue))
        }
        var request = nsdk_discovery_request_t()
        request.struct_size = UInt32(MemoryLayout<nsdk_discovery_request_t>.size)
        request.transport_mask = mask
        copyCString(selectedModelKey, into: &request.selected_model_key)
        try nsdkCheck(nsdk_discovery_start(&request), operation: "startDiscovery")
    }

    public func stopDiscovery() throws {
        try ensureInitialized("stopDiscovery")
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        try nsdkCheck(nsdk_discovery_stop(), operation: "stopDiscovery")
    }

    public func connectReady(
        _ device: DiscoveredDevice,
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        try await connectReady(
            deviceId: device.deviceId,
            transport: device.transportType,
            selectedModelKey: device.modelKey,
            timeoutMilliseconds: timeoutMilliseconds
        )
    }

    public func connectReady(
        deviceId: String,
        transport: TransportType = .bleGatt,
        selectedModelKey: String = "",
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        let session = try connectSession(
            deviceId: deviceId,
            transport: transport,
            selectedModelKey: selectedModelKey
        )
        do {
            try await Task.detached(priority: nil) {
                try session.waitUntilReady(timeoutMilliseconds: timeoutMilliseconds)
            }.value
        } catch {
            try? await session.disconnect()
            throw error
        }
        return session
    }

    private func connectSession(
        deviceId: String,
        transport: TransportType,
        selectedModelKey: String
    ) throws -> ScannerSession {
        try ensureInitialized("connect")
        emitDebug(
            "Connect: deviceId=\(deviceId) transport=\(transport) selectedModel=\(selectedModelKey)"
        )
        if transport == .bleGatt {
            AppleBleRuntime.installTransport()
        }
        var sessionHandle: nsdk_session_handle_t = 0
        try deviceId.withCString { cDeviceID in
            var request = nsdk_connect_request_t()
            request.struct_size = UInt32(MemoryLayout<nsdk_connect_request_t>.size)
            request.device_id = cDeviceID
            request.transport = transport.cValue
            copyCString(selectedModelKey, into: &request.selected_model_key)
            request.model_config_policy = nsdk_model_config_policy_t(NSDK_MODEL_CONFIG_POLICY_ENABLED)
            try nsdkCheck(
                nsdk_session_connect(&request, &sessionHandle),
                operation: "connect"
            )
        }
        let session = ScannerSession(handle: sessionHandle, deviceId: deviceId, transportType: transport, sdk: self)
        var pendingEvents: PendingSessionEvents?
        lock.lock()
        sessions[sessionHandle] = session
        retiredSessionHandles.remove(sessionHandle)
        retiredSessionHandleOrder.removeAll { $0 == sessionHandle }
        pendingEvents = pendingSessionEvents.removeValue(forKey: sessionHandle)
        lock.unlock()
        pendingEvents?.drain(into: session)
        return session
    }

    public func getDeviceModelProfile(_ modelKey: String) -> DeviceModelProfile? {
        DeviceModelProfileBridge.load(modelKey)
    }

    public func getSupportedDeviceModels(transport: TransportType) throws -> [SupportedDeviceModel] {
        try DeviceModelProfileBridge.loadSupportedModels(transport: transport)
    }

    public func getCapabilityDomains(modelKey: String, transport: TransportType) throws -> [CapabilityDomain] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_capability_domain_count(cModelKey, transport.cValue, &count),
                operation: "getCapabilityDomains"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var domain = makeNsdkCapabilityDomain()
                try nsdkCheck(
                    nsdk_capability_domain_get_at(cModelKey, transport.cValue, index, &domain),
                    operation: "getCapabilityDomains"
                )
                return CapabilityDomain(cValue: domain)
            }
        }
    }

    public func getCapabilityLabels(kind: CapabilityLabelKind) throws -> [CapabilityLabel] {
        var count: UInt32 = 0
        try nsdkCheck(
            nsdk_capability_label_count(nsdk_capability_label_kind_t(kind.rawValue), &count),
            operation: "getCapabilityLabels"
        )
        return try loadNativeDefinitions(count: count) { index in
            var label = makeNsdkCapabilityLabel()
            try nsdkCheck(
                nsdk_capability_label_get_at(nsdk_capability_label_kind_t(kind.rawValue), index, &label),
                operation: "getCapabilityLabels"
            )
            return CapabilityLabel(cValue: label)
        }
    }

    public func findCapabilityLabel(kind: CapabilityLabelKind, key: String, ownerKey: String = "") throws -> CapabilityLabel? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findCapabilityLabel requires non-empty key")
        }
        var label = makeNsdkCapabilityLabel()
        return try ownerKey.withCString { cOwnerKey in
            try key.withCString { cKey in
                let code = nsdk_capability_label_find_by_key(
                    nsdk_capability_label_kind_t(kind.rawValue),
                    cOwnerKey,
                    cKey,
                    &label
                )
                if code == 3 {
                    return nil
                }
                try nsdkCheck(code, operation: "findCapabilityLabel")
                return CapabilityLabel(cValue: label)
            }
        }
    }

    public func getCapabilityEntries(modelKey: String, transport: TransportType) throws -> [CapabilityEntry] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_capability_entry_count(cModelKey, transport.cValue, &count),
                operation: "getCapabilityEntries"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var entry = makeNsdkCapabilityEntry()
                try nsdkCheck(
                    nsdk_capability_entry_get_at(cModelKey, transport.cValue, index, &entry),
                    operation: "getCapabilityEntries"
                )
                let entryKey = stringFromCStringBuffer(entry.entry_key)
                return CapabilityEntry(
                    cValue: entry,
                    options: try getCapabilityOptions(modelKey: modelKey, transport: transport, entryKey: entryKey)
                )
            }
        }
    }

    public func findCapabilityEntry(modelKey: String, transport: TransportType, entryKey: String) throws -> CapabilityEntry? {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findCapabilityEntry requires non-empty entry key")
        }
        var entry = makeNsdkCapabilityEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                let code = nsdk_capability_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry)
                if code == 3 {
                    return nil
                }
                try nsdkCheck(code, operation: "findCapabilityEntry")
                return CapabilityEntry(
                    cValue: entry,
                    options: try getCapabilityOptions(modelKey: modelKey, transport: transport, entryKey: entryKey)
                )
            }
        }
    }

    public func getSettingCodeEntries(modelKey: String, transport: TransportType) throws -> [SettingCodeEntry] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_setting_code_entry_count(cModelKey, transport.cValue, &count),
                operation: "getSettingCodeEntries"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var entry = makeNsdkSettingCodeEntry()
                try nsdkCheck(
                    nsdk_setting_code_entry_get_at(cModelKey, transport.cValue, index, &entry),
                    operation: "getSettingCodeEntries"
                )
                return SettingCodeEntry(cValue: entry)
            }
        }
    }

    public func findSettingCodeEntry(modelKey: String, transport: TransportType, entryKey: String) throws -> SettingCodeEntry? {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findSettingCodeEntry requires non-empty entry key")
        }
        var entry = makeNsdkSettingCodeEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try nsdkLookupOrNil(
                    nsdk_setting_code_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry),
                    operation: "findSettingCodeEntry"
                ) {
                    SettingCodeEntry(cValue: entry)
                }
            }
        }
    }

    public func buildSettingCode(
        modelKey: String,
        transport: TransportType,
        entryKey: String,
        value: Data = Data()
    ) throws -> SettingCodeResult {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "buildSettingCode requires non-empty entry key")
        }
        var result = makeNsdkSettingCodeResult()
        try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                let code = value.withUnsafeBytes { rawBuffer in
                    nsdk_build_setting_code(
                        cModelKey,
                        transport.cValue,
                        cEntryKey,
                        value.isEmpty ? nil : rawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        UInt32(value.count),
                        &result
                    )
                }
                try nsdkCheck(code, operation: "buildSettingCode")
            }
        }
        return SettingCodeResult(cValue: result)
    }

    private func getCapabilityOptions(modelKey: String, transport: TransportType, entryKey: String) throws -> [CapabilityOption] {
        guard let entry = try findCapabilityEntryWithoutOptions(modelKey: modelKey, transport: transport, entryKey: entryKey),
              entry.option_count > 0 else {
            return []
        }
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try loadNativeDefinitions(count: entry.option_count) { index in
                    var option = makeNsdkCapabilityOption()
                    try nsdkCheck(
                        nsdk_capability_option_get_at(cModelKey, transport.cValue, cEntryKey, index, &option),
                        operation: "getCapabilityOptions"
                    )
                    return CapabilityOption(cValue: option)
                }
            }
        }
    }

    private func findCapabilityEntryWithoutOptions(modelKey: String, transport: TransportType, entryKey: String) throws -> nsdk_capability_entry_t? {
        var entry = makeNsdkCapabilityEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try nsdkLookupOrNil(
                    nsdk_capability_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry),
                    operation: "findCapabilityEntry"
                ) {
                    entry
                }
            }
        }
    }

    public func getDataRuleKindLabel(_ kind: DataRuleKind) throws -> DataRuleKindLabel {
        var label = makeNsdkDataRuleKindLabel()
        try nsdkCheck(
            nsdk_data_rule_kind_get_label(kind.cValue, &label),
            operation: "getDataRuleKindLabel"
        )
        return DataRuleKindLabel(cValue: label)
    }

    internal func removeSession(handle: UInt64) {
        lock.lock()
        sessions.removeValue(forKey: handle)
        pendingSessionEvents.removeValue(forKey: handle)
        if retiredSessionHandles.insert(handle).inserted {
            retiredSessionHandleOrder.append(handle)
            if retiredSessionHandleOrder.count > Self.maxRetiredSessionHandles {
                retiredSessionHandles.remove(retiredSessionHandleOrder.removeFirst())
            }
        }
        lock.unlock()
    }

    internal func emitDebug(_ message: String) {
        diagnosticsRecorder.record(
            type: "debug",
            level: message.localizedCaseInsensitiveContains("error") ||
                message.localizedCaseInsensitiveContains("failed") ? "error" : "debug",
            message: message
        )
        debugHub.yield(message)
    }

    internal func emitCommandTrace(_ trace: CommandTrace) {
        diagnosticsRecorder.record(
            type: "commandResult",
            level: trace.acknowledged ? "info" : "error",
            message: trace.operation,
            fields: [
                "commandId": "\(trace.timestampMs)",
                "operationKey": trace.operation,
                "success": trace.acknowledged,
                "errorCode": trace.errorCode,
                "elapsedMs": trace.durationMs,
                "transportType": "\(trace.transportType)",
                "resolvedModelId": trace.resolvedModelKey,
                "capabilityEntryKey": trace.entryKey,
                "requestText": trace.requestText,
                "requestHex": trace.requestHex,
                "responseText": trace.responseText,
                "responseHex": trace.responseHex,
            ],
            happenedAt: Date(timeIntervalSince1970: TimeInterval(trace.timestampMs) / 1000.0)
        )
        commandTraceHub.yield(trace)
    }

    internal func onDiscoveryFailure(_ failure: DiscoveryFailure) {
        diagnosticsRecorder.record(
            type: "failure",
            level: "error",
            message: failure.message,
            fields: [
                "operation": "discovery",
                "transportType": "\(failure.transportType)",
                "errorCode": "\(failure.code.rawValue)",
                "platformError": failure.platformErrorCode,
            ]
        )
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

    private func enqueuePendingSessionEvent(_ event: PendingSessionEvent, handle: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        guard !retiredSessionHandles.contains(handle) else {
            emitDebug("Drop late session event for retired handle=\(handle)")
            return
        }
        if pendingSessionEvents[handle] == nil && pendingSessionEvents.count >= Self.maxPendingSessionHandles,
           let oldestHandle = pendingSessionEvents.keys.first {
            pendingSessionEvents.removeValue(forKey: oldestHandle)
            emitDebug("Drop pending session event queue handle=\(oldestHandle)")
        }
        var pending = pendingSessionEvents[handle] ?? PendingSessionEvents()
        if pending.events.count == Self.maxPendingEventsPerSession {
            pending.events.removeFirst()
            emitDebug("Drop oldest pending session event handle=\(handle)")
        }
        pending.events.append(event)
        pendingSessionEvents[handle] = pending
    }

    private static let maxPendingEventsPerSession = 32
    private static let maxPendingSessionHandles = 8
    private static let maxRetiredSessionHandles = 128

    private func installCallbacksIfNeeded() throws {
        guard !callbacksInstalled else { return }
        let userData = Unmanaged.passUnretained(self).toOpaque()
        var callbacks = makeNsdkCallbacks()
        callbacks.discovery_failure_callback = nsdk_swift_discovery_failure_callback
        callbacks.discovery_failure_user_data = userData
        callbacks.discovered_device_callback = nsdk_swift_discovered_device_callback
        callbacks.discovered_device_user_data = userData
        callbacks.session_state_callback = nsdk_swift_state_callback
        callbacks.session_state_user_data = userData
        callbacks.scan_data_callback = nsdk_swift_scan_callback
        callbacks.scan_data_user_data = userData
        callbacks.session_failure_callback = nsdk_swift_session_failure_callback
        callbacks.session_failure_user_data = userData
        callbacks.session_initialization_stage_callback = nsdk_swift_session_initialization_stage_callback
        callbacks.session_initialization_stage_user_data = userData
        callbacks.command_trace_callback = nsdk_swift_command_trace_callback
        callbacks.command_trace_user_data = userData
        callbacks.log_callback = nsdk_swift_log_callback
        callbacks.log_user_data = userData
        try nsdkCheck(nsdk_set_callbacks(&callbacks), operation: "installCallbacks")
        callbacksInstalled = true
    }

    fileprivate func handleDiscovery(deviceID: String, name: String, transport: TransportType) {
        handleDiscovery(deviceID: deviceID, name: name, transport: transport, modelKey: "", matchReason: nil)
    }

    fileprivate func handleDiscovery(
        deviceID: String,
        name: String,
        transport: TransportType,
        modelKey: String,
        matchReason: String?,
        rssi: Int? = nil
    ) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if transport == .bleGatt && normalizedName.isEmpty {
            emitDebug("Drop unnamed BLE discovery deviceId=\(deviceID) model=\(modelKey) reason=\(matchReason ?? "unknown")")
            return
        }
        let device = DiscoveredDevice(
            deviceId: deviceID,
            name: normalizedName,
            transportType: transport,
            modelKey: modelKey,
            matchReason: matchReason,
            rssi: rssi
        )
        let shouldYield: Bool
        lock.lock()
        if let existing = discoveredDevices[deviceID] {
            let nameImproved = existing.name.isEmpty && !device.name.isEmpty
            let nameChanged = !device.name.isEmpty && existing.name != device.name
            let modelChanged = existing.modelKey != device.modelKey
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
        let session = findSession(handle: handle)
        diagnosticsRecorder.record(
            type: "sessionState",
            message: "\(state)",
            fields: [
                "deviceId": session?.deviceId,
                "state": "\(state)",
            ]
        )
        if let session {
            session.onStateChanged(state)
            return
        }
        enqueuePendingSessionEvent(.state(state), handle: handle)
    }

    private func recordScanSummary(
        handle: UInt64,
        timestampMs: UInt64,
        barcodeType: Int32,
        textBytes: Data,
        rawBytes: Data
    ) {
        let text = String(data: textBytes, encoding: .utf8) ?? String(decoding: textBytes, as: UTF8.self)
        diagnosticsRecorder.record(
            type: "scanSummary",
            fields: [
                "deviceId": findSession(handle: handle)?.deviceId,
                "rawBytesLength": rawBytes.count,
                "textBytesLength": textBytes.count,
                "textHash": sha256Short(text),
                "symbology": "\(barcodeType)",
                "rawBytes": [UInt8](rawBytes),
                "text": text,
            ],
            happenedAt: Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
        )
    }

    fileprivate func handleScan(handle: UInt64, scanData: nsdk_scan_data_t) {
        let textBytes = scanData.text_bytes.map { Data(bytes: $0, count: Int(scanData.text_size)) } ?? Data()
        let rawBytes = scanData.raw_bytes.map { Data(bytes: $0, count: Int(scanData.raw_size)) } ?? Data()
        recordScanSummary(
            handle: handle,
            timestampMs: scanData.timestamp_ms,
            barcodeType: scanData.barcode_type,
            textBytes: textBytes,
            rawBytes: rawBytes
        )
        if let session = findSession(handle: handle) {
            session.onScanEvent(
                timestampMs: scanData.timestamp_ms,
                barcodeType: scanData.barcode_type,
                textBytes: textBytes,
                rawBytes: rawBytes
            )
            return
        }
        enqueuePendingSessionEvent(
            .scan(
                PendingScanEvent(
                    timestampMs: scanData.timestamp_ms,
                    barcodeType: scanData.barcode_type,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            ),
            handle: handle
        )
    }

    fileprivate static func describeTransportFailure(
        transport: TransportType,
        issue: TransportIssue
    ) -> String {
        switch transport {
        case .bleGatt:
            switch issue {
            case .bleServiceDiscoveryStartFailed: return "BLE session failed: service discovery could not start"
            case .bleServiceDiscoveryFailed: return "BLE session failed: service discovery failed"
            case .bleNotifyServiceMissing: return "BLE session failed: notify service missing"
            case .bleNotifyCharacteristicMissing: return "BLE session failed: notify characteristic missing"
            case .bleNotificationEnableFailed: return "BLE session failed: enabling notifications failed"
            case .bleNotifyDescriptorMissing: return "BLE session failed: notify descriptor missing"
            case .bleNotifyDescriptorWriteFailed: return "BLE session failed: notify descriptor write failed"
            case .connectionTimeout: return "BLE session failed: connection timed out"
            case .bleGattFailure: return "BLE session failed: platform GATT failure"
            case .platformError: return "BLE session failed: platform connection status error"
            case .unknown: return "BLE session failed: unknown transport error"
            }
        case .usbHid:
            return issue == .platformError
                ? "UsbHid session failed: platform transport status error"
                : "UsbHid session failed: transport error"
        case .usbSerial:
            return issue == .platformError
                ? "UsbSerial session failed: platform transport status error"
                : "UsbSerial session failed: transport error"
        case .sppClassic:
            return issue == .platformError
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
        retiredSessionHandles.removeAll()
        retiredSessionHandleOrder.removeAll()
        lock.unlock()
    }

    internal func terminateSessionsForSdkShutdownForTesting() {
        lock.lock()
        let activeSessions = Array(sessions.values)
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        lock.unlock()
        for session in activeSessions {
            session.terminateForSdkShutdown()
        }
    }

    internal func simulatePendingState(_ state: SessionState, handle: UInt64) {
        handleState(handle: handle, state: state)
    }

    internal func simulatePendingFailure(
        handle: UInt64,
        transport: TransportType,
        issue: TransportIssue,
        platformErrorCode: Int32
    ) {
        var failure = nsdk_session_failure_t()
        failure.transport = transport.cValue
        failure.issue = nsdk_transport_issue_t(issue.rawValue)
        failure.platform_error = platformErrorCode
        failure.platform_error_available = 1
        handleSessionFailure(handle: handle, failure: failure)
    }

    internal func simulatePendingScan(
        handle: UInt64,
        timestampMs: UInt64,
        barcodeType: Int32,
        textBytes: Data,
        rawBytes: Data
    ) {
        recordScanSummary(
            handle: handle,
            timestampMs: timestampMs,
            barcodeType: barcodeType,
            textBytes: textBytes,
            rawBytes: rawBytes
        )
        if let session = findSession(handle: handle) {
            session.onScanEvent(
                timestampMs: timestampMs,
                barcodeType: barcodeType,
                textBytes: textBytes,
                rawBytes: rawBytes
            )
            return
        }
        enqueuePendingSessionEvent(
            .scan(
                PendingScanEvent(
                    timestampMs: timestampMs,
                    barcodeType: barcodeType,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            ),
            handle: handle
        )
    }

    internal func simulatePendingInitializationStage(
        handle: UInt64,
        selectedModelKey: String,
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
                    selectedModelKey: selectedModelKey,
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
        enqueuePendingSessionEvent(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelKey: selectedModelKey,
                    stage: stage,
                    timestampMs: timestampMs,
                    traceId: traceId,
                    success: success,
                    errorCode: errorCode,
                    message: message
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleSessionFailure(handle: UInt64, failure: nsdk_session_failure_t) {
        let transport = TransportType(rawValue: failure.transport) ?? .bleGatt
        let issue = TransportIssue(rawValue: failure.issue) ?? .unknown
        let activeSession = findSession(handle: handle)
        let sessionFailure = SessionFailure(
            sessionHandle: handle,
            deviceId: activeSession?.deviceId ?? "",
            transportType: transport,
            issue: issue,
            message: ScannerSDK.describeTransportFailure(transport: transport, issue: issue),
            platformErrorCode: failure.platform_error_available != 0 ? failure.platform_error : nil
        )
        diagnosticsRecorder.record(
            type: "failure",
            level: "error",
            message: sessionFailure.message,
            fields: [
                "deviceId": sessionFailure.deviceId,
                "transportType": "\(sessionFailure.transportType)",
                "transportIssue": "\(sessionFailure.issue.rawValue)",
                "platformError": sessionFailure.platformErrorCode,
            ]
        )
        sessionFailureHub.yield(sessionFailure)
        if let session = activeSession {
            session.onFailure(sessionFailure)
            return
        }
        enqueuePendingSessionEvent(
            .failure(
                PendingSessionFailure(
                    transport: transport,
                    issue: issue,
                    platformErrorCode: failure.platform_error_available != 0 ? failure.platform_error : nil
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleSessionInitializationStage(handle: UInt64, event: nsdk_session_initialization_stage_event_t) {
        let stageEvent = SessionInitializationStageEvent(
            sessionHandle: handle,
            deviceId: findSession(handle: handle)?.deviceId ?? "",
            selectedModelKey: stringFromCStringBuffer(event.selected_model_key),
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
        enqueuePendingSessionEvent(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelKey: stageEvent.selectedModelKey,
                    stage: stageEvent.stage,
                    timestampMs: stageEvent.timestampMs,
                    traceId: stageEvent.traceId,
                    success: stageEvent.success,
                    errorCode: stageEvent.errorCode,
                    message: stageEvent.message
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleCommandTrace(handle: UInt64, trace: nsdk_command_trace_t) {
        let value = CommandTrace(cValue: trace)
        emitCommandTrace(value)
        if let session = findSession(handle: handle) {
            session.onCommandTrace(value)
        }
    }

    fileprivate func handleNativeLog(level: Int32, message: String) {
        if message.hasPrefix("[NSDKAppleBLE]") {
            let bleMessage = message
                .replacingOccurrences(of: "[NSDKAppleBLE]", with: "BLE")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            emitDebug(bleMessage)
            return
        }
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
    let issue: TransportIssue
    let platformErrorCode: Int32?
}

private struct PendingSessionInitializationStage {
    let selectedModelKey: String
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
                        issue: failure.issue,
                        message: ScannerSDK.describeTransportFailure(transport: failure.transport, issue: failure.issue),
                        platformErrorCode: failure.platformErrorCode
                    )
                )
            case .initializationStage(let stage):
                session.onInitializationStage(
                    SessionInitializationStageEvent(
                        sessionHandle: session.handle,
                        deviceId: session.deviceId,
                        selectedModelKey: stage.selectedModelKey,
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
        transport: TransportType(rawValue: value.transport) ?? .bleGatt,
        modelKey: stringFromCStringBuffer(value.model_key),
        matchReason: matchReason.isEmpty ? nil : matchReason,
        rssi: value.rssi_available != 0 ? Int(value.rssi) : nil
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
    event: UnsafePointer<nsdk_session_initialization_stage_event_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let event else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleSessionInitializationStage(handle: session, event: event.pointee)
}

private func nsdk_swift_command_trace_callback(
    session: nsdk_session_handle_t,
    trace: UnsafePointer<nsdk_command_trace_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let trace else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleCommandTrace(handle: session, trace: trace.pointee)
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
