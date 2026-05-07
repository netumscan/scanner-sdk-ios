import Foundation

public enum Ntc06hTemplateInputType: String, Sendable {
    case none = ""
    case hexUInt8 = "HEX_UINT8"
    case decimalRange = "DECIMAL_RANGE"
    case enumeration = "ENUM"
}

public struct Ntc06hSettingDefinition: Sendable {
    public let key: String
    public let settingCode: String
    public let displayCode: String
    public let displayName: String
    public let group: String
    public let domainKey: String
    public let familyKey: String
    public let sectionKey: String
    public let notes: String
    public let requiresSave: Bool
    public let isTemplate: Bool
    public let templateHint: String
    public let templateExampleCode: String
    public let templateInputType: Ntc06hTemplateInputType
    public let templateInputWidth: Int
    public let templateInputMin: Int
    public let templateInputMax: Int

    public init(
        key: String,
        settingCode: String,
        displayCode: String = "",
        displayName: String,
        group: String,
        domainKey: String,
        familyKey: String,
        sectionKey: String,
        notes: String,
        requiresSave: Bool,
        isTemplate: Bool = false,
        templateHint: String = "",
        templateExampleCode: String = "",
        templateInputType: Ntc06hTemplateInputType = .none,
        templateInputWidth: Int = 0,
        templateInputMin: Int = 0,
        templateInputMax: Int = 0
    ) {
        self.key = key
        self.settingCode = settingCode
        self.displayCode = displayCode
        self.displayName = displayName
        self.group = group
        self.domainKey = domainKey
        self.familyKey = familyKey
        self.sectionKey = sectionKey
        self.notes = notes
        self.requiresSave = requiresSave
        self.isTemplate = isTemplate
        self.templateHint = templateHint
        self.templateExampleCode = templateExampleCode
        self.templateInputType = templateInputType
        self.templateInputWidth = templateInputWidth
        self.templateInputMin = templateInputMin
        self.templateInputMax = templateInputMax
    }
}

public struct Ntc06hSettingLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public extension Ntc06hSettingDefinition {
    var localizedTitleLabel: Ntc06hSettingLabel {
        Ntc06hSettingLabel(
            localizationKey: "nsdk.ntc06h_setting.\(key)",
            fallbackDisplayName: displayName
        )
    }
}
