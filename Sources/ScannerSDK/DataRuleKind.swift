import Foundation
import CNSDK

public enum DataRuleKind: UInt32, Sendable {
    case suffix = 1
    case prefix = 2
    case hideEnd = 3
    case hideMiddle = 4
    case hideStart = 5
    case replace = 7

    internal var cValue: nsdk_data_rule_kind_t {
        nsdk_data_rule_kind_t(rawValue: rawValue)
    }
}

public struct DataRuleKindLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_data_rule_kind_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}
