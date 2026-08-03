import Foundation
import CNSDK

final class StreamHub<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private let capacity: Int
    private var onDrop: (() -> Void)?
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var finished = false

    init(capacity: Int = 64) {
        self.capacity = max(1, capacity)
    }

    func makeStream() -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: .bufferingNewest(capacity)) { continuation in
            let id = UUID()
            lock.lock()
            let shouldFinish = finished
            if !shouldFinish {
                continuations[id] = continuation
            }
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.remove(id: id)
            }
            if shouldFinish {
                continuation.finish()
            }
        }
    }

    func yield(_ value: Element) {
        lock.lock()
        let targets = Array(continuations.values)
        lock.unlock()
        for continuation in targets {
            if case .dropped = continuation.yield(value) {
                onDrop?()
            }
        }
    }

    func setOnDrop(_ callback: @escaping () -> Void) {
        lock.lock()
        onDrop = callback
        lock.unlock()
    }

    func finish() {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        let targets = Array(continuations.values)
        continuations.removeAll()
        lock.unlock()
        for continuation in targets {
            continuation.finish()
        }
    }

    private func remove(id: UUID) {
        lock.lock()
        continuations.removeValue(forKey: id)
        lock.unlock()
    }
}

func nsdkCheck(_ code: nsdk_error_t, operation: String) throws {
    guard code == 0 else {
        throw ScannerError(code: code, operation: operation)
    }
}

func nsdkLookupOrNil<T>(
    _ code: nsdk_error_t,
    operation: String,
    map: () -> T
) throws -> T? {
    if code == 3 {
        return nil
    }
    try nsdkCheck(code, operation: operation)
    return map()
}

func makeNsdkScannerInfo() -> nsdk_scanner_info_t {
    var value = nsdk_scanner_info_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_scanner_info_t>.size)
    return value
}

func makeNsdkBatteryInfo() -> nsdk_battery_info_t {
    var value = nsdk_battery_info_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_battery_info_t>.size)
    return value
}

func makeNsdkStorageUsage() -> nsdk_storage_usage_t {
    var value = nsdk_storage_usage_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_storage_usage_t>.size)
    return value
}

func makeNsdkDeviceCapabilitySummary() -> nsdk_device_capability_summary_t {
    var value = nsdk_device_capability_summary_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_device_capability_summary_t>.size)
    return value
}

func makeNsdkDeviceModelProfile() -> nsdk_device_model_profile_t {
    var value = nsdk_device_model_profile_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_device_model_profile_t>.size)
    value.capability.struct_size = UInt32(MemoryLayout<nsdk_device_capability_summary_t>.size)
    return value
}

func makeNsdkSupportedDeviceModel() -> nsdk_supported_device_model_t {
    var value = nsdk_supported_device_model_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_supported_device_model_t>.size)
    value.profile.struct_size = UInt32(MemoryLayout<nsdk_device_model_profile_t>.size)
    value.profile.capability.struct_size = UInt32(MemoryLayout<nsdk_device_capability_summary_t>.size)
    return value
}

func makeNsdkSessionOperationSupport() -> nsdk_session_operation_support_t {
    var value = nsdk_session_operation_support_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_session_operation_support_t>.size)
    return value
}

func makeNsdkCapabilityValueResult() -> nsdk_capability_value_result_t {
    var value = nsdk_capability_value_result_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_value_result_t>.size)
    return value
}

func makeNsdkCommandResponse() -> nsdk_command_response_t {
    var value = nsdk_command_response_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_command_response_t>.size)
    return value
}

func makeNsdkCapabilityWriteRequest() -> nsdk_capability_write_request_t {
    var value = nsdk_capability_write_request_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_write_request_t>.size)
    return value
}

func makeNsdkCapabilityActionRequest() -> nsdk_capability_action_request_t {
    var value = nsdk_capability_action_request_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_action_request_t>.size)
    return value
}

func makeNsdkCapabilityDomain() -> nsdk_capability_domain_t {
    var value = nsdk_capability_domain_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_domain_t>.size)
    return value
}

func makeNsdkCapabilityOption() -> nsdk_capability_option_t {
    var value = nsdk_capability_option_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_option_t>.size)
    return value
}

func makeNsdkCapabilityLabel() -> nsdk_capability_label_t {
    var value = nsdk_capability_label_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_label_t>.size)
    return value
}

func makeNsdkLocalizationEntry() -> nsdk_localization_entry_t {
    var value = nsdk_localization_entry_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_localization_entry_t>.size)
    return value
}

func makeNsdkCapabilityEntry() -> nsdk_capability_entry_t {
    var value = nsdk_capability_entry_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_capability_entry_t>.size)
    return value
}

func makeNsdkSettingCodeEntry() -> nsdk_setting_code_entry_t {
    var value = nsdk_setting_code_entry_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_setting_code_entry_t>.size)
    return value
}

func makeNsdkSettingCodeResult() -> nsdk_setting_code_result_t {
    var value = nsdk_setting_code_result_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_setting_code_result_t>.size)
    return value
}

func makeNsdkCallbacks() -> nsdk_callbacks_t {
    var value = nsdk_callbacks_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_callbacks_t>.size)
    return value
}

func makeNsdkDataRuleKindLabel() -> nsdk_data_rule_kind_label_t {
    var value = nsdk_data_rule_kind_label_t()
    value.struct_size = UInt32(MemoryLayout<nsdk_data_rule_kind_label_t>.size)
    return value
}

func loadNativeDefinitions<T>(
    count: UInt32,
    loader: (UInt32) throws -> T
) throws -> [T] {
    guard count > 0 else {
        return []
    }

    var definitions: [T] = []
    definitions.reserveCapacity(Int(count))
    for index in 0..<count {
        definitions.append(try loader(index))
    }
    return definitions
}

func stringFromCStringBuffer<T>(_ value: T) -> String {
    var copy = value
    return withUnsafePointer(to: &copy) {
        $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<T>.size) { ptr in
            String(cString: ptr)
        }
    }
}

func copyCString<T>(_ value: String, into destination: inout T) {
    var bytes = Array(value.utf8.prefix(max(0, MemoryLayout<T>.size - 1)))
    bytes.append(0)
    withUnsafeMutableBytes(of: &destination) { rawBuffer in
        rawBuffer.initializeMemory(as: UInt8.self, repeating: 0)
        for (index, byte) in bytes.enumerated() where index < rawBuffer.count {
            rawBuffer[index] = byte
        }
    }
}

func stringFromCStringPointer(_ value: UnsafePointer<CChar>?) -> String {
    guard let value else {
        return ""
    }
    return String(cString: value)
}

func copyBytes(
    copy: (_ buffer: UnsafeMutablePointer<UInt8>?, _ capacity: UInt32, _ outLength: UnsafeMutablePointer<UInt32>?) -> nsdk_error_t,
    operation: String
) throws -> Data {
    var requiredLength: UInt32 = 0
    try nsdkCheck(copy(nil, 0, &requiredLength), operation: "\(operation).length")
    if requiredLength == 0 {
        return Data()
    }
    var bytes = [UInt8](repeating: 0, count: Int(requiredLength))
    var copiedLength: UInt32 = 0
    let code = bytes.withUnsafeMutableBufferPointer { buffer in
        copy(buffer.baseAddress, UInt32(buffer.count), &copiedLength)
    }
    try nsdkCheck(code, operation: operation)
    guard copiedLength == requiredLength else {
        throw ScannerError(code: -1, operation: "\(operation) returned inconsistent length")
    }
    return Data(bytes)
}

func decodeCStringTable<T>(
    _ value: T,
    entrySize: Int,
    count: UInt32
) -> [String] {
    guard entrySize > 0, count > 0 else {
        return []
    }

    return withUnsafeBytes(of: value) { rawBuffer in
        let totalEntries = min(Int(count), rawBuffer.count / entrySize)
        return (0..<totalEntries).compactMap { index in
            let start = index * entrySize
            let end = start + entrySize
            let slice = rawBuffer[start..<end]
            guard let nulIndex = slice.firstIndex(of: 0) else {
                return String(decoding: Array(slice), as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard nulIndex > start else {
                return nil
            }
            return String(decoding: Array(rawBuffer[start..<nulIndex]), as: UTF8.self)
        }
    }
}

func decodeUInt16Table<T>(
    _ value: T,
    count: UInt32
) -> [Int] {
    guard count > 0 else {
        return []
    }

    return withUnsafeBytes(of: value) { rawBuffer in
        let elements = rawBuffer.bindMemory(to: UInt16.self)
        let totalEntries = min(Int(count), elements.count)
        return Array(elements.prefix(totalEntries)).map(Int.init)
    }
}
