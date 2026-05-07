import Foundation

public enum Nt212xParameterKind: Sendable {
    case unknown
    case bool
    case `enum`
    case uint8
    case uint16
    case bytesAscii
    case action
    case complex
    case custom
}

public struct Nt212xParameterDefinition: Sendable {
    public let parameterID: UInt16
    public let key: String
    public let aliasName: String?
    public let displayName: String
    public let symbol: String
    public let group: String
    public let domainKey: String
    public let familyKey: String
    public let sectionKey: String
    public let defaultValue: String
    public let notes: String
    public let optionsJSON: String
    public let kind: Nt212xParameterKind

    public init(
        parameterID: UInt16,
        key: String,
        aliasName: String?,
        displayName: String,
        symbol: String,
        group: String,
        domainKey: String,
        familyKey: String,
        sectionKey: String,
        defaultValue: String,
        notes: String = "",
        optionsJSON: String,
        kind: Nt212xParameterKind
    ) {
        self.parameterID = parameterID
        self.key = key
        self.aliasName = aliasName
        self.displayName = displayName
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
