import Foundation

public enum Nt280hParameterKind: Sendable {
    case unknown
    case bool
    case `enum`
    case action
    case object
}

public struct Nt280hParameterDefinition: Sendable {
    public let parameterID: UInt16
    public let exID: UInt8
    public let exCMD: UInt8
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
    public let kind: Nt280hParameterKind
    public let isPlaceholder: Bool

    public init(
        parameterID: UInt16,
        exID: UInt8,
        exCMD: UInt8,
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
        kind: Nt280hParameterKind,
        isPlaceholder: Bool
    ) {
        self.parameterID = parameterID
        self.exID = exID
        self.exCMD = exCMD
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
        self.isPlaceholder = isPlaceholder
    }
}
