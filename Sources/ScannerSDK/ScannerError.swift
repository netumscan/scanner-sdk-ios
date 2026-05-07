import Foundation

public struct ScannerError: Error, Sendable, CustomStringConvertible {
    public let code: Int32
    public let operation: String

    public init(code: Int32, operation: String) {
        self.code = code
        self.operation = operation
    }

    public var description: String {
        "ScannerError(operation: \(operation), code: \(code))"
    }
}
