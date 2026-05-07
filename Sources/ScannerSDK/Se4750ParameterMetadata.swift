import Foundation

public enum Se4750ParameterKind: Sendable {
    case unknown
    case bool
    case `enum`
    case uint8
    case uint16
    case bytesAscii
}

public struct Se4750ParameterDefinition: Sendable {
    public let parameterID: UInt32
    public let key: String
    public let displayName: String
    public let semanticName: String
    public let symbol: String
    public let group: String
    public let domainKey: String
    public let familyKey: String
    public let sectionKey: String
    public let defaultValue: String
    public let notes: String
    public let optionsJSON: String
    public let kind: Se4750ParameterKind

    public init(
        parameterID: UInt32,
        key: String,
        displayName: String,
        semanticName: String,
        symbol: String,
        group: String,
        domainKey: String,
        familyKey: String,
        sectionKey: String,
        defaultValue: String,
        notes: String,
        optionsJSON: String,
        kind: Se4750ParameterKind
    ) {
        self.parameterID = parameterID
        self.key = key
        self.displayName = displayName
        self.semanticName = semanticName
        self.symbol = symbol
        self.group = group
        self.domainKey = domainKey
        self.familyKey = familyKey
        self.sectionKey = sectionKey
        self.defaultValue = defaultValue
        self.notes = notes
        self.optionsJSON = optionsJSON
        self.kind = kind
    }
}
