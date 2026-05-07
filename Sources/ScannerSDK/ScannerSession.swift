import Foundation
import CNSDK

public final class ScannerSession: @unchecked Sendable {
    public let handle: UInt64
    public let deviceId: String
    public let transportType: TransportType

    private weak var sdk: ScannerSDK?
    private let stateHub = StreamHub<SessionState>()
    private let scanHub = StreamHub<ScanEvent>()
    private let failureHub = StreamHub<SessionFailure>()
    private let lock = NSLock()
    private var currentState: SessionState = .idle
    private var scanTextCharset: ScanTextCharset = .utf8
    private var scanTerminator: Data = Data([0x0D])

    internal init(handle: UInt64, deviceId: String, transportType: TransportType, sdk: ScannerSDK) {
        self.handle = handle
        self.deviceId = deviceId
        self.transportType = transportType
        self.sdk = sdk
    }

    public var state: AsyncStream<SessionState> {
        stateHub.makeStream()
    }

    public var scanEvents: AsyncStream<ScanEvent> {
        scanHub.makeStream()
    }

    public var failureEvents: AsyncStream<SessionFailure> {
        failureHub.makeStream()
    }

    public var latestState: SessionState {
        lock.lock()
        defer { lock.unlock() }
        return currentState
    }

    public func setScanTextCharset(_ charset: ScanTextCharset) {
        lock.lock()
        scanTextCharset = charset
        lock.unlock()
    }

    public func getScanTextCharset() -> ScanTextCharset {
        lock.lock()
        defer { lock.unlock() }
        return scanTextCharset
    }

    public func setScanTerminator(_ bytes: Data) throws {
        try ensureReady("setScanTerminator")
        precondition(!bytes.isEmpty, "terminator must not be empty")
        var mutable = bytes
        let code = mutable.withUnsafeMutableBytes { rawBuffer in
            nsdk_set_scan_terminator(
                handle,
                rawBuffer.bindMemory(to: UInt8.self).baseAddress,
                UInt32(rawBuffer.count)
            )
        }
        try nsdkCheck(code, operation: "setScanTerminator")
        lock.lock()
        scanTerminator = bytes
        lock.unlock()
    }

    public func getScanTerminator() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return scanTerminator
    }

    public func refreshInfo() throws -> ScannerInfo {
        try ensureReady("refreshInfo")
        var info = nsdk_scanner_info_t()
        try nsdkCheck(nsdk_refresh_info(handle, &info), operation: "refreshInfo")
        return makeScannerInfo(info)
    }

    public func initializeSession(applyModelConfig: Bool = true) throws -> SessionInitializationResult {
        try ensureReady("initializeSession")
        var info = nsdk_scanner_info_t()
        var batteryInfo = nsdk_battery_info_t()
        var modelConfigApplied: Int32 = 0
        try nsdkCheck(
            nsdk_initialize_session(handle, applyModelConfig ? 1 : 0, &info, &batteryInfo, &modelConfigApplied),
            operation: "initializeSession"
        )
        let result = SessionInitializationResult(
            info: makeScannerInfo(info),
            batteryInfo: makeBatteryInfo(batteryInfo),
            modelConfigApplied: modelConfigApplied != 0
        )
        emitDebug(
            "initializeSession applyModelConfig=\(applyModelConfig) modelConfigApplied=\(result.modelConfigApplied) firmware=\(result.info.firmwareVersion) battery=\(result.batteryInfo.rawText)"
        )
        return result
    }

    public func getCachedInfo() throws -> ScannerInfo {
        try ensureReady("getCachedInfo")
        var info = nsdk_scanner_info_t()
        try nsdkCheck(nsdk_get_cached_info(handle, &info), operation: "getCachedInfo")
        return makeScannerInfo(info)
    }

    public func getResolvedModelId() throws -> DeviceModelId {
        try ensureReady("getResolvedModelId")
        var modelID = nsdk_device_model_id_t(rawValue: 0)
        try nsdkCheck(nsdk_get_resolved_model_id(handle, &modelID), operation: "getResolvedModelId")
        let resolved = DeviceModelId(rawValue: modelID.rawValue) ?? .unknown
        emitDebug("resolvedModel=\(resolved)")
        return resolved
    }

    public func setPreferredModel(
        _ modelId: DeviceModelId,
        applyDecoderModule: Bool = true
    ) throws {
        guard modelId != .unknown else {
            throw ScannerError(code: -1, operation: "setPreferredModel requires non-unknown model")
        }
        try nsdkCheck(
            nsdk_set_preferred_model(
                handle,
                nsdk_device_model_id_t(rawValue: modelId.rawValue),
                applyDecoderModule ? 1 : 0
            ),
            operation: "setPreferredModel"
        )
        emitDebug("setPreferredModel model=\(modelId) applyDecoderModule=\(applyDecoderModule)")
    }

    public func getDeviceCapabilitySummary() throws -> DeviceCapabilitySummary {
        try ensureReady("getDeviceCapabilitySummary")
        var summary = nsdk_device_capability_summary_t()
        try nsdkCheck(
            nsdk_get_device_capability_summary(handle, &summary),
            operation: "getDeviceCapabilitySummary"
        )
        let capability = makeDeviceCapabilitySummary(summary)
        emitDebug("capability \(capability.displaySummary)")
        emitCapabilityDiagnostics(capability)
        return capability
    }

    public func getOperationSupportSummary() throws -> SessionOperationSupportSummary {
        try ensureReady("getOperationSupportSummary")
        var support = nsdk_session_operation_support_t()
        try nsdkCheck(
            nsdk_get_session_operation_support(handle, &support),
            operation: "getOperationSupportSummary"
        )
        return SessionOperationSupportSummary(
            supportsRefreshInfo: support.supports_refresh_info != 0,
            supportsInitializeSession: support.supports_initialize_session != 0,
            supportsGetBatteryInfo: support.supports_get_battery_info != 0,
            supportsExecuteBasicDeviceCommands: support.supports_execute_basic_device_commands != 0,
            supportsExecuteTextCommands: support.supports_execute_text_commands != 0,
            supportsExecuteDataRuleCommands: support.supports_execute_data_rule_commands != 0,
            supportsDefaultModuleCommandProbe: support.supports_default_module_command_probe != 0,
            supportsTriggerScan: support.supports_trigger_scan != 0,
            supportsBeep: support.supports_beep != 0,
            supportsDisableAckBeep: support.supports_disable_ack_beep != 0,
            supportsVibrateOn: support.supports_vibrate_on != 0,
            supportsVibrateOff: support.supports_vibrate_off != 0
        )
    }

    internal func makeScannerInfo(_ info: nsdk_scanner_info_t) -> ScannerInfo {
        return ScannerInfo(
            deviceId: stringFromCStringBuffer(info.device_id),
            name: stringFromCStringBuffer(info.name),
            serialNumber: stringFromCStringBuffer(info.serial_number),
            firmwareVersion: stringFromCStringBuffer(info.firmware_version),
            hardwareVersion: stringFromCStringBuffer(info.hardware_version),
            manufacturer: stringFromCStringBuffer(info.manufacturer),
            versionFormatFamily: stringFromCStringBuffer(info.version_format_family),
            versionBootCode: stringFromCStringBuffer(info.version_boot_code),
            versionSeriesCode: stringFromCStringBuffer(info.version_series_code),
            versionTransportCode: stringFromCStringBuffer(info.version_transport_code),
            versionTransportSuffix: stringFromCStringBuffer(info.version_transport_suffix),
            versionWirelessCode: stringFromCStringBuffer(info.version_wireless_code),
            versionBluetoothCode: stringFromCStringBuffer(info.version_bluetooth_code),
            versionChipsetCode: stringFromCStringBuffer(info.version_chipset_code),
            versionChipsetSuffix: stringFromCStringBuffer(info.version_chipset_suffix),
            versionReleaseCode: stringFromCStringBuffer(info.version_release_code),
            versionExtensionCode: stringFromCStringBuffer(info.version_extension_code)
        )
    }

    internal func makeDeviceCapabilitySummary(_ summary: nsdk_device_capability_summary_t) -> DeviceCapabilitySummary {
        DeviceCapabilitySummary(
            modelId: DeviceModelId(rawValue: summary.model_id.rawValue) ?? .unknown,
            modelName: stringFromCStringBuffer(summary.model_name),
            defaultCommandSet: CommandSetKind(rawValue: summary.default_command_set.rawValue) ?? .unknown,
            formFactor: DeviceFormFactor(rawValue: summary.form_factor.rawValue) ?? .unknown,
            moduleFamily: ModuleFamily(rawValue: summary.module_family.rawValue) ?? .unknown,
            supportsBasicDeviceCommands: summary.supports_basic_device_commands != 0,
            supportsMasterCommands: summary.supports_master_commands != 0,
            supportsNativeModuleCommands: summary.supports_native_module_commands != 0,
            supportsModuleCommandBridge: summary.supports_module_command_bridge != 0,
            supportsModuleCommands: summary.supports_module_commands != 0,
            supportsScannerMaster: summary.supports_scanner_master != 0,
            supportsModulePassthrough: summary.supports_module_passthrough != 0,
            supportStatus: SupportStatus(rawValue: summary.support_status.rawValue) ?? .unknown
        )
    }

    internal func makeBatteryInfo(_ info: nsdk_battery_info_t) -> BatteryInfo {
        BatteryInfo(
            rawText: stringFromCStringBuffer(info.raw_text),
            voltageText: stringFromCStringBuffer(info.voltage_text),
            percent: Int(info.percent)
        )
    }

    public func getBatteryInfo() throws -> BatteryInfo {
        try ensureReady("getBatteryInfo")
        var info = nsdk_battery_info_t()
        try nsdkCheck(nsdk_get_battery_info(handle, &info), operation: "getBatteryInfo")
        return makeBatteryInfo(info)
    }

    public func getCachedBatteryInfo() throws -> BatteryInfo? {
        try ensureReady("getCachedBatteryInfo")
        var info = nsdk_battery_info_t()
        let batteryInfo = try nsdkLookupOrNil(
            nsdk_get_cached_battery_info(handle, &info),
            operation: "getCachedBatteryInfo"
        ) {
            makeBatteryInfo(info)
        }
        if let batteryInfo {
            emitDebug("cachedBattery raw=\(batteryInfo.rawText) percent=\(batteryInfo.percent)")
        } else {
            emitDebug("cachedBattery unavailable")
        }
        return batteryInfo
    }

    public func executeBasicDeviceCommand(_ command: BasicDeviceCommand) throws -> CommandResponse {
        try ensureReady("executeBasicDeviceCommand")
        var response = nsdk_command_response_t()
        try nsdkCheck(
            nsdk_execute_basic_device_command(handle, command.cValue, &response),
            operation: "executeBasicDeviceCommand"
        )
        return try makeCommandResponse(response)
    }

    public func executeMasterCommand(_ commandID: Int32) throws -> CommandResponse {
        try ensureReady("executeMasterCommand")
        var response = nsdk_command_response_t()
        try nsdkCheck(
            nsdk_execute_master_command(handle, commandID, &response),
            operation: "executeMasterCommand"
        )
        return try makeCommandResponse(response)
    }

    public func executeMasterCommand(_ command: MasterCommand) throws -> CommandResponse {
        try executeMasterCommand(command.cValue)
    }

    public func executeTextCommand(_ commandText: String) throws -> CommandResponse {
        try ensureReady("executeTextCommand")
        precondition(!commandText.isEmpty, "commandText must not be empty")
        var response = nsdk_command_response_t()
        try commandText.withCString { cText in
            try nsdkCheck(
                nsdk_execute_text_command(handle, cText, &response),
                operation: "executeTextCommand"
            )
        }
        return try makeCommandResponse(response)
    }

    public func executeDataRuleCommand(
        kind: DataRuleKind,
        primary: Data,
        secondary: Data = Data()
    ) throws -> CommandResponse {
        try ensureReady("executeDataRuleCommand")
        var response = nsdk_command_response_t()
        var primaryCopy = primary
        var secondaryCopy = secondary
        let code = primaryCopy.withUnsafeMutableBytes { primaryBuffer in
            secondaryCopy.withUnsafeMutableBytes { secondaryBuffer in
                nsdk_execute_data_rule_command(
                    handle,
                    kind.cValue,
                    primaryBuffer.bindMemory(to: UInt8.self).baseAddress,
                    UInt32(primaryBuffer.count),
                    secondaryBuffer.bindMemory(to: UInt8.self).baseAddress,
                    UInt32(secondaryBuffer.count),
                    &response
                )
            }
        }
        try nsdkCheck(code, operation: "executeDataRuleCommand")
        return try makeCommandResponse(response)
    }

    public func executeModuleCommand(
        family: ModuleFamily,
        kind: ModuleCommandKind,
        parameterID: UInt32 = 0,
        payload: Data = Data(),
        persist: Bool = false
    ) throws -> CommandResponse {
        try ensureReady("executeModuleCommand")
        var response = nsdk_command_response_t()
        var payloadCopy = payload
        let code = payloadCopy.withUnsafeMutableBytes { payloadBuffer in
            nsdk_execute_module_command(
                handle,
                family.cValue,
                kind.cValue,
                parameterID,
                payloadBuffer.bindMemory(to: UInt8.self).baseAddress,
                UInt32(payloadBuffer.count),
                persist ? 1 : 0,
                &response
            )
        }
        try nsdkCheck(code, operation: "executeModuleCommand")
        return try makeCommandResponse(response)
    }

    public func executeModuleRawFrame(
        family: ModuleFamily,
        frame: Data
    ) throws -> CommandResponse {
        try ensureReady("executeModuleRawFrame")
        precondition(!frame.isEmpty, "frame must not be empty")
        var response = nsdk_command_response_t()
        var frameCopy = frame
        let code = frameCopy.withUnsafeMutableBytes { frameBuffer in
            nsdk_execute_module_raw_frame(
                handle,
                family.cValue,
                frameBuffer.bindMemory(to: UInt8.self).baseAddress,
                UInt32(frameBuffer.count),
                &response
            )
        }
        try nsdkCheck(code, operation: "executeModuleRawFrame")
        return try makeCommandResponse(response)
    }

    public func canExecuteMasterCommand(_ commandID: Int32) throws -> Bool {
        try ensureReady("canExecuteMasterCommand")
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_can_execute_master_command(handle, commandID, &supported),
            operation: "canExecuteMasterCommand"
        )
        let result = supported != 0
        emitDebug("masterCommandProbe command=\(commandID) supported=\(result)")
        return result
    }

    public func canExecuteMasterCommand(_ command: MasterCommand) throws -> Bool {
        try canExecuteMasterCommand(command.cValue)
    }

    public func canExecuteModuleCommand(
        family: ModuleFamily,
        kind: ModuleCommandKind,
        parameterID: UInt32 = 0,
        persist: Bool = false
    ) throws -> Bool {
        try ensureReady("canExecuteModuleCommand")
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_can_execute_module_command(
                handle,
                family.cValue,
                kind.cValue,
                parameterID,
                persist ? 1 : 0,
                &supported
            ),
            operation: "canExecuteModuleCommand"
        )
        let result = supported != 0
        emitDebug(
            "moduleCommandProbe family=\(family) kind=\(kind) parameterID=\(parameterID) persist=\(persist) supported=\(result)"
        )
        return result
    }

    public func canExecuteDefaultModuleCommandProbe(
        family: ModuleFamily
    ) throws -> Bool {
        try ensureReady("canExecuteDefaultModuleCommandProbe")
        var supported: Int32 = 0
        try nsdkCheck(
            nsdk_can_execute_default_module_command_probe(handle, family.cValue, &supported),
            operation: "canExecuteDefaultModuleCommandProbe"
        )
        let result = supported != 0
        emitDebug("defaultModuleProbe family=\(family) supported=\(result)")
        if !result {
            emitDebug("capability-warning defaultModuleProbeUnavailable family=\(family)")
        }
        return result
    }

    public func triggerScan() throws {
        try ensureReady("triggerScan")
        try nsdkCheck(nsdk_trigger_scan(handle), operation: "triggerScan")
    }

    public func beep() throws {
        try ensureReady("beep")
        try nsdkCheck(nsdk_beep(handle), operation: "beep")
    }

    public func disableAckBeep() throws {
        try ensureReady("disableAckBeep")
        try nsdkCheck(nsdk_disable_ack_beep(handle), operation: "disableAckBeep")
    }

    public func vibrateOn() throws {
        try ensureReady("vibrateOn")
        try nsdkCheck(nsdk_vibrate_on(handle), operation: "vibrateOn")
    }

    public func vibrateOff() throws {
        try ensureReady("vibrateOff")
        try nsdkCheck(nsdk_vibrate_off(handle), operation: "vibrateOff")
    }

    public func disconnect() throws {
        try nsdkCheck(nsdk_disconnect(handle), operation: "disconnect")
    }

    internal func waitUntilReady(timeoutMilliseconds: UInt32 = 10_000) throws {
        try nsdkCheck(
            nsdk_wait_until_ready(handle, timeoutMilliseconds),
            operation: "waitUntilReady"
        )
    }

    internal func onStateChanged(_ state: SessionState) {
        lock.lock()
        currentState = state
        lock.unlock()
        emitDebug("state=\(state)")
        stateHub.yield(state)
        if state == .disconnected {
            sdk?.removeSession(handle: handle)
        }
    }

    internal func onScanEvent(timestampMs: UInt64, barcodeType: Int32, textBytes: Data, rawBytes: Data) {
        let charset = getScanTextCharset()
        let text = String(data: textBytes, encoding: charset.encoding) ?? String(decoding: textBytes, as: UTF8.self)
        scanHub.yield(
            ScanEvent(
                timestampMs: timestampMs,
                barcodeType: barcodeType,
                text: text,
                textBytes: textBytes,
                rawBytes: rawBytes
            )
        )
    }

    internal func onFailure(_ failure: SessionFailure) {
        emitDebug(
            "failure transport=\(failure.transportType) code=\(failure.code) issue=\(String(describing: failure.bleTransportIssue)) platformError=\(String(describing: failure.platformErrorCode))"
        )
        failureHub.yield(failure)
    }

    private func ensureReady(_ operation: String) throws {
        let state = latestState
        guard state == .ready else {
            emitDebug("reject \(operation) requiresReady actual=\(state)")
            throw ScannerError(code: -1, operation: "\(operation) requires READY state, actual=\(state)")
        }
    }

    private func emitDebug(_ message: String) {
        sdk?.emitDebug("session[\(handle)] \(message)")
    }

    private func emitCapabilityDiagnostics(_ capability: DeviceCapabilitySummary) {
        for message in capabilityDiagnostics(capability) {
            emitDebug(message)
        }
    }

    internal func capabilityDiagnostics(_ capability: DeviceCapabilitySummary) -> [String] {
        var messages: [String] = []
        if capability.supportStatus != .verified {
            messages.append("capability-warning supportStatus=\(capability.supportStatus)")
        }
        if capability.supportsModuleCommands {
            if !capability.supportsNativeModuleCommands && !capability.supportsModuleCommandBridge {
                messages.append("capability-warning moduleCommandsWithoutNativeOrBridge family=\(capability.moduleFamily)")
            }
        } else if capability.moduleFamily != .unknown {
            messages.append("capability-warning moduleFamily=\(capability.moduleFamily) but moduleCommands=false")
        }
        if capability.supportsModulePassthrough && !capability.supportsModuleCommands {
            messages.append("capability-warning passthroughOnly family=\(capability.moduleFamily)")
        }
        return messages
    }

    private func makeCommandResponse(_ response: nsdk_command_response_t) throws -> CommandResponse {
        var mutableResponse = response
        let textBytes = try copyBytes(
            expectedLength: mutableResponse.text_size,
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_text_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyTextBytes"
        )

        let rawBytes = try copyBytes(
            expectedLength: mutableResponse.raw_size,
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_raw_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyRawBytes"
        )
        let modulePayloadBytes = try copyBytes(
            expectedLength: mutableResponse.module_payload_size,
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_module_payload_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyModulePayloadBytes"
        )
        let moduleParameterValueBytes = try copyBytes(
            expectedLength: mutableResponse.module_parameter_value_size,
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_module_parameter_value_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyModuleParameterValueBytes"
        )
        let collector = RecordCollector()
        let pointer = Unmanaged.passRetained(collector).toOpaque()
        defer { Unmanaged<RecordCollector>.fromOpaque(pointer).release() }
        nsdk_command_response_for_each_record(&mutableResponse, nsdk_swift_record_callback, pointer)
        return CommandResponse(
            textBytes: textBytes,
            textFullSize: Int(mutableResponse.text_full_size),
            textBytesComplete: mutableResponse.text_size >= mutableResponse.text_full_size,
            rawBytes: rawBytes,
            acknowledged: mutableResponse.acknowledged != 0,
            recordCount: Int(mutableResponse.record_count),
            recordBytes: collector.records,
            recordsComplete: mutableResponse.records_complete != 0,
            modulePayloadBytes: modulePayloadBytes,
            modulePayloadFullSize: Int(mutableResponse.module_payload_full_size),
            moduleParameterID: Int(mutableResponse.module_parameter_id),
            moduleParameterValueBytes: moduleParameterValueBytes,
            moduleParameterValueFullSize: Int(mutableResponse.module_parameter_value_full_size),
            moduleParameterValueAvailable: mutableResponse.module_parameter_value_available != 0
        )
    }
}

private final class RecordCollector {
    var records: [Data] = []
}

private func nsdk_swift_record_callback(
    index: UInt32,
    text: UnsafePointer<CChar>?,
    textLength: UInt32,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let text else { return }
    let collector = Unmanaged<RecordCollector>.fromOpaque(userData).takeUnretainedValue()
    collector.records.append(Data(bytes: text, count: Int(textLength)))
}
