import Foundation

public enum DataRuleValidationError: Error, Sendable, Equatable {
    case empty(String)
    case tooLong(String, maximum: Int)
    case outOfRange(String, range: ClosedRange<Int>)
}

public struct DataRule: Sendable, Equatable {
    public let kind: DataRuleKind
    private let primaryBytes: Data
    private let secondaryBytes: Data

    private init(kind: DataRuleKind, primary: Data, secondary: Data = Data()) {
        self.kind = kind
        self.primaryBytes = primary
        self.secondaryBytes = secondary
    }

    public var primary: Data { primaryBytes }

    public var secondary: Data { secondaryBytes }

    public static func suffix(_ text: String) throws -> DataRule {
        try suffix(asciiBytes(text))
    }

    public static func suffix(_ bytes: Data) throws -> DataRule {
        try validateAffix(bytes, name: "suffix")
        return DataRule(kind: .suffix, primary: bytes)
    }

    public static func prefix(_ text: String) throws -> DataRule {
        try prefix(asciiBytes(text))
    }

    public static func prefix(_ bytes: Data) throws -> DataRule {
        try validateAffix(bytes, name: "prefix")
        return DataRule(kind: .prefix, primary: bytes)
    }

    public static func hideEnd(_ length: Int) throws -> DataRule {
        try validateByteValue(length, name: "length")
        return DataRule(kind: .hideEnd, primary: Data([UInt8(length)]))
    }

    public static func hideMiddle(start: Int, length: Int) throws -> DataRule {
        try validateByteValue(start, name: "start")
        try validateByteValue(length, name: "length")
        return DataRule(kind: .hideMiddle, primary: Data([UInt8(start)]), secondary: Data([UInt8(length)]))
    }

    public static func hideStart(_ length: Int) throws -> DataRule {
        try validateByteValue(length, name: "length")
        return DataRule(kind: .hideStart, primary: Data([UInt8(length)]))
    }

    public static func replace(source: String, target: String) throws -> DataRule {
        try replace(source: asciiBytes(source), target: asciiBytes(target))
    }

    public static func replace(source: Data, target: Data) throws -> DataRule {
        guard !source.isEmpty else { throw DataRuleValidationError.empty("source") }
        guard source.count <= 6 else { throw DataRuleValidationError.tooLong("source", maximum: 6) }
        guard target.count <= 5 else { throw DataRuleValidationError.tooLong("target", maximum: 5) }
        guard source.count + target.count <= 6 else { throw DataRuleValidationError.tooLong("source + target", maximum: 6) }
        return DataRule(kind: .replace, primary: source, secondary: target)
    }

    internal var cPayload: (kind: DataRuleKind, primary: Data, secondary: Data) {
        (kind, primaryBytes, secondaryBytes)
    }

    private static func validateAffix(_ bytes: Data, name: String) throws {
        guard !bytes.isEmpty else { throw DataRuleValidationError.empty(name) }
        guard bytes.count <= 10 else { throw DataRuleValidationError.tooLong(name, maximum: 10) }
    }

    private static func validateByteValue(_ value: Int, name: String) throws {
        guard (1...255).contains(value) else {
            throw DataRuleValidationError.outOfRange(name, range: 1...255)
        }
    }

    private static func asciiBytes(_ text: String) -> Data {
        Data(text.unicodeScalars.map { scalar in
            scalar.value <= 0x7F ? UInt8(scalar.value) : UInt8(ascii: "?")
        })
    }
}
