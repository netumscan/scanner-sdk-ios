import Foundation
import CNSDK

public final class ScannerSession: @unchecked Sendable {
    public let handle: UInt64
    public let deviceId: String
    public let transportType: TransportType

    private weak var sdk: ScannerSDK?
    private let stateHub = StreamHub<SessionState>()
    private let scanHub = StreamHub<ScanEvent>()
    private let eventOverflowHub = StreamHub<EventOverflow>(capacity: 32)
    private let failureHub = StreamHub<SessionFailure>()
    private let initializationStageHub = StreamHub<SessionInitializationStageEvent>()
    private let commandTraceHub = StreamHub<CommandTrace>()
    private let lock = NSLock()
    private let operationQueue = DispatchQueue(label: "com.netumscan.scannersdk.session.operations")
    private var currentState: SessionState = .idle
    private var scanTextCharset: ScanTextCharset = .utf8
    private var scanTerminator: Data = Data([0x0D])
    private var scanDroppedCount: UInt64 = 0
    private var terminatedBySdkShutdown = false

    internal init(handle: UInt64, deviceId: String, transportType: TransportType, sdk: ScannerSDK) {
        self.handle = handle
        self.deviceId = deviceId
        self.transportType = transportType
        self.sdk = sdk
        scanHub.setOnDrop { [weak self] in self?.recordScanOverflow() }
    }

    public var state: AsyncStream<SessionState> {
        stateHub.makeStream()
    }

    public var scanEvents: AsyncStream<ScanEvent> {
        scanHub.makeStream()
    }

    public var eventOverflows: AsyncStream<EventOverflow> {
        eventOverflowHub.makeStream()
    }

    public var failureEvents: AsyncStream<SessionFailure> {
        failureHub.makeStream()
    }

    public var initializationStages: AsyncStream<SessionInitializationStageEvent> {
        initializationStageHub.makeStream()
    }

    public var commandTraces: AsyncStream<CommandTrace> {
        commandTraceHub.makeStream()
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

    public func setScanTextTerminator(_ bytes: Data) throws {
        try ensureReady("setScanTextTerminator")
        guard !bytes.isEmpty else {
            throw DataRuleValidationError.empty("scan terminator")
        }
        var mutable = bytes
        let code = mutable.withUnsafeMutableBytes { rawBuffer in
            nsdk_session_set_scan_text_terminator(
                handle,
                rawBuffer.bindMemory(to: UInt8.self).baseAddress,
                UInt32(rawBuffer.count)
            )
        }
        try nsdkCheck(code, operation: "setScanTextTerminator")
        lock.lock()
        scanTerminator = bytes
        lock.unlock()
    }

    public func setScanTextTerminator(_ bytes: Data) async throws {
        try await performNative { try self.setScanTextTerminator(bytes) }
    }

    public func getScanTextTerminator() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return scanTerminator
    }

    public func refreshInfo() throws -> ScannerInfo {
        try ensureReady("refreshInfo")
        var info = makeNsdkScannerInfo()
        try nsdkCheck(nsdk_session_refresh_scanner_info(handle, &info), operation: "refreshInfo")
        return makeScannerInfo(info)
    }

    public func refreshInfo() async throws -> ScannerInfo {
        try await performNative { try self.refreshInfo() }
    }

    public func initialize() throws -> SessionInitializationResult {
        try ensureReady("initialize")
        var info = makeNsdkScannerInfo()
        var batteryInfo = makeNsdkBatteryInfo()
        var modelConfigApplied: Int32 = 0
        try nsdkCheck(
            nsdk_session_initialize(handle, &info, &batteryInfo, &modelConfigApplied),
            operation: "initialize"
        )
        let result = SessionInitializationResult(
            info: makeScannerInfo(info),
            batteryInfo: makeBatteryInfo(batteryInfo),
            modelConfigApplied: modelConfigApplied != 0
        )
        emitDebug(
            "initialize modelConfigApplied=\(result.modelConfigApplied) firmware=\(result.info.firmwareVersion) battery=\(result.batteryInfo.rawText)"
        )
        return result
    }

    public func initialize() async throws -> SessionInitializationResult {
        try await performNative { try self.initialize() }
    }

    public func getCachedInfo() throws -> ScannerInfo {
        try ensureReady("getCachedInfo")
        var info = makeNsdkScannerInfo()
        try nsdkCheck(nsdk_session_get_cached_scanner_info(handle, &info), operation: "getCachedInfo")
        return makeScannerInfo(info)
    }

    public func getResolvedModelKey() throws -> String {
        try ensureReady("getResolvedModelKey")
        var modelKey = [CChar](repeating: 0, count: 64)
        try modelKey.withUnsafeMutableBufferPointer { buffer in
            try nsdkCheck(
                nsdk_session_get_resolved_model_key(handle, buffer.baseAddress, UInt32(buffer.count)),
                operation: "getResolvedModelKey"
            )
        }
        let resolved = String(cString: modelKey)
        emitDebug("resolvedModel=\(resolved)")
        return resolved
    }

    public func getDeviceCapabilitySummary() throws -> DeviceCapabilitySummary {
        try ensureReady("getDeviceCapabilitySummary")
        var summary = makeNsdkDeviceCapabilitySummary()
        try nsdkCheck(
            nsdk_session_get_device_capability_summary(handle, &summary),
            operation: "getDeviceCapabilitySummary"
        )
        let capability = DeviceCapabilitySummary(cValue: summary)
        emitDebug("publicCapability \(capability.displaySummary)")
        return capability
    }

    public func getCapabilityDomains() throws -> [CapabilityDomain] {
        try ensureReady("getCapabilityDomains")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "getCapabilityDomains requires active SDK")
        }
        return try sdk.getCapabilityDomains(modelKey: getResolvedModelKey(), transport: transportType)
    }

    public func getCapabilityLabels(kind: CapabilityLabelKind) throws -> [CapabilityLabel] {
        try ensureReady("getCapabilityLabels")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "getCapabilityLabels requires active SDK")
        }
        return try sdk.getCapabilityLabels(kind: kind)
    }

    public func findCapabilityLabel(kind: CapabilityLabelKind, key: String, ownerKey: String = "") throws -> CapabilityLabel? {
        try ensureReady("findCapabilityLabel")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "findCapabilityLabel requires active SDK")
        }
        return try sdk.findCapabilityLabel(kind: kind, key: key, ownerKey: ownerKey)
    }

    public func getCapabilityEntries() throws -> [CapabilityEntry] {
        try ensureReady("getCapabilityEntries")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "getCapabilityEntries requires active SDK")
        }
        return try sdk.getCapabilityEntries(modelKey: getResolvedModelKey(), transport: transportType)
    }

    public func findCapabilityEntry(_ entryKey: String) throws -> CapabilityEntry? {
        try ensureReady("findCapabilityEntry")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "findCapabilityEntry requires active SDK")
        }
        return try sdk.findCapabilityEntry(modelKey: getResolvedModelKey(), transport: transportType, entryKey: entryKey)
    }

    public func getSettingCodeEntries() throws -> [SettingCodeEntry] {
        try ensureReady("getSettingCodeEntries")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "getSettingCodeEntries requires active SDK")
        }
        return try sdk.getSettingCodeEntries(modelKey: getResolvedModelKey(), transport: transportType)
    }

    public func findSettingCodeEntry(_ entryKey: String) throws -> SettingCodeEntry? {
        try ensureReady("findSettingCodeEntry")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "findSettingCodeEntry requires active SDK")
        }
        return try sdk.findSettingCodeEntry(modelKey: getResolvedModelKey(), transport: transportType, entryKey: entryKey)
    }

    public func buildSettingCode(_ entryKey: String, value: Data = Data()) throws -> SettingCodeResult {
        try ensureReady("buildSettingCode")
        guard let sdk else {
            throw ScannerError(code: -1, operation: "buildSettingCode requires active SDK")
        }
        return try sdk.buildSettingCode(modelKey: getResolvedModelKey(), transport: transportType, entryKey: entryKey, value: value)
    }

    public func readCapabilityValue(_ entryKey: String) throws -> CapabilityValue {
        try ensureReady("readCapabilityValue")
        let entry = try resolveCapabilityEntry(entryKey, operation: "readCapabilityValue")
        guard entry.kind == .setting && entry.supportsRead else {
            throw ScannerError(code: -1, operation: "readCapabilityValue unsupported entry=\(entryKey)")
        }
        var result = makeNsdkCapabilityValueResult()
        try entryKey.withCString { cEntryKey in
            try nsdkCheck(
                nsdk_session_read_capability_value(handle, cEntryKey, &result),
                operation: "readCapabilityValue"
            )
        }
        guard result.value_available != 0 else {
            throw ScannerError(code: 11, operation: "readCapabilityValue")
        }
        var mutableResult = result
        defer { nsdk_capability_value_result_dispose(&mutableResult) }
        let valueBytes = try copyBytes(
            copy: { buffer, capacity, outLength in
                nsdk_capability_value_result_copy_full_value_bytes(&mutableResult, buffer, capacity, outLength)
            },
            operation: "readCapabilityValue.copyValueBytes"
        )
        return try decodeCapabilityValue(entry, bytes: valueBytes)
    }

    public func writeCapabilityValue(
        _ entryKey: String,
        value: CapabilityValue,
        persist: Bool = true
    ) throws -> CommandResponse {
        try ensureReady("writeCapabilityValue")
        let entry = try resolveCapabilityEntry(entryKey, operation: "writeCapabilityValue")
        guard entry.kind == .setting && entry.supportsWrite else {
            throw ScannerError(code: -1, operation: "writeCapabilityValue unsupported entry=\(entryKey)")
        }
        let valueBytes = try encodeCapabilityValue(entry, value: value)
        var response = makeNsdkCommandResponse()
        let payload = valueBytes
        var request = makeNsdkCapabilityWriteRequest()
        request.value_size = UInt32(payload.count)
        request.persist = persist ? 1 : 0
        try entryKey.withCString { cEntryKey in
            let code = payload.withUnsafeBytes { payloadBuffer in
                request.entry_key = cEntryKey
                request.value_bytes = payloadBuffer.bindMemory(to: UInt8.self).baseAddress
                return nsdk_session_write_capability_value(
                    handle,
                    &request,
                    &response
                )
            }
            try nsdkCheck(code, operation: "writeCapabilityValue")
        }
        return try makeCommandResponse(response)
    }

    public func executeCapabilityAction(
        _ entryKey: String,
        value: Data = Data()
    ) throws -> CommandResponse {
        try ensureReady("executeCapabilityAction")
        let entry = try resolveCapabilityEntry(entryKey, operation: "executeCapabilityAction")
        guard entry.kind == .action && entry.supportsExecute else {
            throw ScannerError(code: -1, operation: "executeCapabilityAction unsupported entry=\(entryKey)")
        }
        var request = makeNsdkCapabilityActionRequest()
        request.value_size = UInt32(value.count)
        let payload = value
        var response = makeNsdkCommandResponse()
        try entryKey.withCString { cEntryKey in
            let code = payload.withUnsafeBytes { payloadBuffer in
                request.entry_key = cEntryKey
                request.value_bytes = payloadBuffer.bindMemory(to: UInt8.self).baseAddress
                return nsdk_session_execute_capability_action(handle, &request, &response)
            }
            try nsdkCheck(code, operation: "executeCapabilityAction")
        }
        return try makeCommandResponse(response)
    }

    public func getOperationSupport() throws -> SessionOperationSupport {
        try ensureReady("getOperationSupport")
        var support = makeNsdkSessionOperationSupport()
        try nsdkCheck(
            nsdk_session_get_operation_support(handle, &support),
            operation: "getOperationSupport"
        )
        return SessionOperationSupport(
            supportsRefreshInfo: support.supports_refresh_info != 0,
            supportsInitializeSession: support.supports_initialize_session != 0,
            supportsGetBatteryInfo: support.supports_get_battery_info != 0,
            supportsApplyDataRule: support.supports_apply_data_rule != 0,
            supportsTriggerScan: support.supports_trigger_scan != 0,
            supportsSetAckBeepEnabled: support.supports_set_ack_beep_enabled != 0,
            supportsSetVibrationEnabled: support.supports_set_vibration_enabled != 0
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
            versionExtensionCode: stringFromCStringBuffer(info.version_extension_code),
            bluetoothName: stringFromCStringBuffer(info.bluetooth_name),
            bluetoothFirmwareVersion: stringFromCStringBuffer(info.bluetooth_firmware_version)
        )
    }

    internal func makeBatteryInfo(_ info: nsdk_battery_info_t) -> BatteryInfo {
        BatteryInfo(
            rawText: stringFromCStringBuffer(info.raw_text),
            voltageText: stringFromCStringBuffer(info.voltage_text),
            percent: Int(info.percent)
        )
    }

    internal func makeStorageUsage(_ usage: nsdk_storage_usage_t) -> StorageUsage {
        StorageUsage(
            barcodeCount: Int(usage.barcode_count),
            used: Int(usage.used),
            capacity: Int(usage.capacity),
            remaining: Int(usage.remaining),
            rawText: stringFromCStringBuffer(usage.raw_text)
        )
    }

    public func getBatteryInfo() throws -> BatteryInfo {
        try ensureReady("getBatteryInfo")
        var info = makeNsdkBatteryInfo()
        try nsdkCheck(nsdk_session_get_battery_info(handle, &info), operation: "getBatteryInfo")
        return makeBatteryInfo(info)
    }

    public func getBatteryInfo() async throws -> BatteryInfo {
        try await performNative { try self.getBatteryInfo() }
    }

    public func getCachedBatteryInfo() throws -> BatteryInfo? {
        try ensureReady("getCachedBatteryInfo")
        var info = makeNsdkBatteryInfo()
        let batteryInfo = try nsdkLookupOrNil(
            nsdk_session_get_cached_battery_info(handle, &info),
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

    public func getStorageUsage() throws -> StorageUsage {
        try ensureReady("getStorageUsage")
        var usage = makeNsdkStorageUsage()
        try nsdkCheck(nsdk_session_get_storage_usage(handle, &usage), operation: "getStorageUsage")
        return makeStorageUsage(usage)
    }

    public func setBluetoothName(_ name: String) throws -> CommandResponse {
        try executeCapabilityAction("action.SetBluetoothName", value: Data(name.utf8))
    }

    public func setBluetoothName(_ name: String) async throws -> CommandResponse {
        try await performNative { try self.setBluetoothName(name) }
    }

    public func setTimestamp(_ date: Date = Date(), timeZone: TimeZone = .current) throws -> CommandResponse {
        let offsetLookupDate = date.addingTimeInterval(1)
        let unixMillis = Int64((date.timeIntervalSince1970 * 1000).rounded())
        let offsetSeconds = Int32(timeZone.secondsFromGMT(for: offsetLookupDate))
        var response = makeNsdkCommandResponse()
        try nsdkCheck(
            nsdk_session_set_rtc_timestamp(handle, unixMillis, offsetSeconds, &response),
            operation: "setTimestamp"
        )
        return try makeCommandResponse(response)
    }

    public func setAckBeepEnabled(_ enabled: Bool) throws -> CommandResponse {
        try writeCapabilityValue("setting.SetAckBeepEnabled", value: .boolean(enabled))
    }

    public func setVibrationEnabled(_ enabled: Bool) throws -> CommandResponse {
        try writeCapabilityValue("setting.SetVibrationEnabled", value: .boolean(enabled))
    }

    public func applyDataRule(_ rule: DataRule) throws -> CommandResponse {
        try ensureReady("applyDataRule")
        var response = makeNsdkCommandResponse()
        let payload = rule.cPayload
        var primary = payload.primary
        var secondary = payload.secondary
        let code = primary.withUnsafeMutableBytes { primaryBuffer in
            secondary.withUnsafeMutableBytes { secondaryBuffer in
                nsdk_session_apply_data_rule(
                    handle,
                    payload.kind.cValue,
                    primaryBuffer.bindMemory(to: UInt8.self).baseAddress,
                    UInt32(primaryBuffer.count),
                    secondaryBuffer.bindMemory(to: UInt8.self).baseAddress,
                    UInt32(secondaryBuffer.count),
                    &response
                )
            }
        }
        try nsdkCheck(code, operation: "applyDataRule")
        return try makeCommandResponse(response)
    }

    public func applyDataRule(_ rule: DataRule) async throws -> CommandResponse {
        try await performNative { try self.applyDataRule(rule) }
    }

    public func triggerScan() throws {
        _ = try executeCapabilityAction("action.TriggerScan")
    }

    public func triggerScan() async throws {
        try await performNative { try self.triggerScan() }
    }

    public func disconnect() throws {
        try ensureNotTerminated("disconnect")
        defer { onStateChanged(.disconnected) }
        try nsdkCheck(nsdk_session_disconnect(handle), operation: "disconnect")
    }

    public func disconnect() async throws {
        try await performNative { try self.disconnect() }
    }

    private func performNative<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            operationQueue.async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    internal func waitUntilReady(timeoutMilliseconds: UInt32 = 10_000) throws {
        try nsdkCheck(
            nsdk_session_wait_until_ready(handle, timeoutMilliseconds),
            operation: "waitUntilReady"
        )
    }

    internal func onStateChanged(_ state: SessionState) {
        lock.lock()
        if terminatedBySdkShutdown {
            lock.unlock()
            return
        }
        currentState = state
        lock.unlock()
        emitDebug("state=\(state)")
        stateHub.yield(state)
        if state == .disconnected || state == .error {
            sdk?.removeSession(handle: handle)
        }
    }

    internal func onScanEvent(timestampMs: UInt64, barcodeType: Int32, textBytes: Data, rawBytes: Data) {
        guard !isTerminatedBySdkShutdown else { return }
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
        guard !isTerminatedBySdkShutdown else { return }
        emitDebug(
            "failure transport=\(failure.transportType) issue=\(failure.issue) platformError=\(String(describing: failure.platformErrorCode))"
        )
        failureHub.yield(failure)
    }

    internal func onInitializationStage(_ event: SessionInitializationStageEvent) {
        guard !isTerminatedBySdkShutdown else { return }
        emitDebug(
            "initializeSession stage=\(event.stage) trace=\(event.traceId) success=\(event.success) error=\(event.errorCode) message=\(event.message ?? "")"
        )
        initializationStageHub.yield(event)
    }

    internal func onCommandTrace(_ trace: CommandTrace) {
        guard !isTerminatedBySdkShutdown else { return }
        commandTraceHub.yield(trace)
    }

    internal func terminateForSdkShutdown() {
        lock.lock()
        let shouldPublishDisconnected = !terminatedBySdkShutdown && currentState != .disconnected
        terminatedBySdkShutdown = true
        currentState = .disconnected
        lock.unlock()

        if shouldPublishDisconnected {
            emitDebug("state=disconnected (SDK shutdown)")
            stateHub.yield(.disconnected)
        }
        stateHub.finish()
        scanHub.finish()
        eventOverflowHub.finish()
        failureHub.finish()
        initializationStageHub.finish()
        commandTraceHub.finish()
    }

    private func recordScanOverflow() {
        lock.lock()
        scanDroppedCount += 1
        let count = scanDroppedCount
        lock.unlock()
        eventOverflowHub.yield(EventOverflow(source: .scan, droppedCount: count))
    }

    private func resolveCapabilityEntry(_ entryKey: String, operation: String) throws -> CapabilityEntry {
        try ensureReady(operation)
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "\(operation) requires non-empty capability entry key")
        }
        guard let entry = try findCapabilityEntry(entryKey) else {
            throw ScannerError(code: -1, operation: "\(operation) unknown capability entry=\(entryKey)")
        }
        return entry
    }

    private func decodeCapabilityValue(_ entry: CapabilityEntry, bytes: Data) throws -> CapabilityValue {
        switch entry.valueKind {
        case .boolean:
            guard bytes.count == 1 else {
                throw ScannerError(code: -1, operation: "readCapabilityValue expected single-byte boolean response")
            }
            return .boolean(bytes.first != 0x00)
        case .bytesAscii:
            let text = String(data: bytes, encoding: .ascii) ?? String(decoding: bytes, as: UTF8.self)
            return CapabilityValue(kind: .bytesAscii, bytes: bytes, textValue: text)
        default:
            return .bytes(entry.valueKind, bytes)
        }
    }

    private func encodeCapabilityValue(_ entry: CapabilityEntry, value: CapabilityValue) throws -> Data {
        if entry.valueKind == .boolean {
            if let booleanValue = value.booleanValue {
                return Data([booleanValue ? 0x01 : 0x00])
            }
            if value.bytes.count == 1 {
                return value.bytes
            }
            throw ScannerError(code: -1, operation: "writeCapabilityValue boolean value requires Bool or one byte")
        }

        if entry.valueKind == .bytesAscii, let textValue = value.textValue {
            return Data(textValue.utf8)
        }

        if value.kind != entry.valueKind && value.kind != .custom && value.kind != .unknown {
            throw ScannerError(
                code: -1,
                operation: "writeCapabilityValue value kind \(value.kind) does not match entry kind \(entry.valueKind)"
            )
        }
        return value.bytes
    }

    private func ensureReady(_ operation: String) throws {
        try ensureNotTerminated(operation)
        let state = latestState
        guard state == .ready else {
            emitDebug("reject \(operation) requiresReady actual=\(state)")
            throw ScannerError(code: -1, operation: "\(operation) requires READY state, actual=\(state)")
        }
    }

    private var isTerminatedBySdkShutdown: Bool {
        lock.lock()
        defer { lock.unlock() }
        return terminatedBySdkShutdown
    }

    private func ensureNotTerminated(_ operation: String) throws {
        guard !isTerminatedBySdkShutdown else {
            throw ScannerError(code: -1, operation: "\(operation) unavailable after SDK shutdown")
        }
    }

    private func emitDebug(_ message: String) {
        sdk?.emitDebug("session[\(handle)] \(message)")
    }

    private func makeCommandResponse(_ response: nsdk_command_response_t) throws -> CommandResponse {
        var mutableResponse = response
        defer { nsdk_command_response_dispose(&mutableResponse) }
        let textBytes = try copyBytes(
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_full_text_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyTextBytes"
        )

        let rawBytes = try copyBytes(
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_full_raw_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "commandResponse.copyRawBytes"
        )
        let collector = RecordCollector()
        let pointer = Unmanaged.passRetained(collector).toOpaque()
        defer { Unmanaged<RecordCollector>.fromOpaque(pointer).release() }
        try nsdkCheck(
            nsdk_command_response_for_each_record(&mutableResponse, nsdk_swift_record_callback, pointer),
            operation: "commandResponse.forEachRecord"
        )
        return CommandResponse(
            textBytes: textBytes,
            textFullSize: Int(mutableResponse.text_full_size),
            textBytesComplete: mutableResponse.text_size >= mutableResponse.text_full_size,
            rawBytes: rawBytes,
            acknowledged: mutableResponse.acknowledged != 0,
            recordCount: Int(mutableResponse.record_count),
            recordBytes: collector.records,
            recordsComplete: mutableResponse.records_complete != 0
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
