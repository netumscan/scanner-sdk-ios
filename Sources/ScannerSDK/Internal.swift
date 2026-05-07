import Foundation
import CNSDK

final class StreamHub<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    func makeStream() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.remove(id: id)
            }
        }
    }

    func yield(_ value: Element) {
        lock.lock()
        let targets = Array(continuations.values)
        lock.unlock()
        for continuation in targets {
            continuation.yield(value)
        }
    }

    func finish() {
        lock.lock()
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

func stringFromCStringPointer(_ value: UnsafePointer<CChar>?) -> String {
    guard let value else {
        return ""
    }
    return String(cString: value)
}

func copyBytes(
    expectedLength: UInt32,
    copy: (_ buffer: UnsafeMutablePointer<UInt8>?, _ capacity: UInt32, _ outLength: UnsafeMutablePointer<UInt32>?) -> nsdk_error_t,
    operation: String
) throws -> Data {
    var outLength: UInt32 = 0
    if expectedLength == 0 {
        try nsdkCheck(copy(nil, 0, &outLength), operation: operation)
        return Data()
    }
    var bytes = [UInt8](repeating: 0, count: Int(expectedLength))
    let code = bytes.withUnsafeMutableBufferPointer { buffer in
        copy(buffer.baseAddress, UInt32(buffer.count), &outLength)
    }
    guard code == 0 || code == -1 else {
        throw ScannerError(code: code, operation: operation)
    }
    return Data(bytes.prefix(Int(min(outLength, UInt32(bytes.count)))))
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
