import Foundation
import CNSDK

public enum ModuleFamily: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case ntc06h = 1
    case nt280h = 2
    case nt212x = 3
    case se4750 = 4

    public var localizedLabel: ModuleFamilyLabel {
        switch self {
        case .unknown:
            return ModuleFamilyLabel(localizationKey: "nsdk.module_family.unknown_module", fallbackDisplayName: "Unknown module")
        case .ntc06h:
            return ModuleFamilyLabel(localizationKey: "nsdk.module_family.ntc06h", fallbackDisplayName: "NTC06H")
        case .nt280h:
            return ModuleFamilyLabel(localizationKey: "nsdk.module_family.nt280h", fallbackDisplayName: "NT280H")
        case .nt212x:
            return ModuleFamilyLabel(localizationKey: "nsdk.module_family.nt212x", fallbackDisplayName: "NT212X")
        case .se4750:
            return ModuleFamilyLabel(localizationKey: "nsdk.module_family.se4750", fallbackDisplayName: "SE4750")
        }
    }

    internal var cValue: nsdk_decoder_module_family_t {
        nsdk_decoder_module_family_t(rawValue: rawValue)
    }
}

public struct ModuleFamilyLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public enum ModuleCommandKind: UInt32, CaseIterable, Sendable {
    case rawFrame = 0
    case readVersion = 1
    case startDecode = 2
    case stopDecode = 3
    case readParameter = 4
    case writeParameter = 5
    case factoryDefaults = 6
    case saveSettings = 7
    case scanEnable = 8
    case scanDisable = 9
    case sleep = 10
    case reset = 11
    case ledOn = 12
    case ledOff = 13
    case ack = 14
    case nak = 15
    case capabilitiesRequest = 16
    case aimOn = 17
    case aimOff = 18
    case illuminationOn = 19
    case illuminationOff = 20
    case changeAllCodeTypes = 21
    case beep = 22
    case pagerMotorActivation = 23

    internal var cValue: nsdk_module_command_kind_t {
        nsdk_module_command_kind_t(rawValue: rawValue)
    }
}

public struct ModuleCommandKindLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_module_command_kind_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct ModuleActionPresetLabel: Sendable {
    public let actionID: String
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(actionID: String, localizationKey: String, fallbackDisplayName: String) {
        self.actionID = actionID
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_module_action_preset_label_t) {
        actionID = stringFromCStringBuffer(cValue.action_id)
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct ModuleTestRecommendation: Sendable, Hashable {
    public let recommendationID: String
    public let titleKey: String
    public let titleFallback: String
    public let detailKey: String
    public let detailFallback: String

    public init(
        recommendationID: String,
        titleKey: String,
        titleFallback: String,
        detailKey: String,
        detailFallback: String
    ) {
        self.recommendationID = recommendationID
        self.titleKey = titleKey
        self.titleFallback = titleFallback
        self.detailKey = detailKey
        self.detailFallback = detailFallback
    }

    internal init(cValue: nsdk_module_test_recommendation_t) {
        recommendationID = stringFromCStringBuffer(cValue.recommendation_id)
        titleKey = stringFromCStringBuffer(cValue.title_key)
        titleFallback = stringFromCStringBuffer(cValue.title_fallback)
        detailKey = stringFromCStringBuffer(cValue.detail_key)
        detailFallback = stringFromCStringBuffer(cValue.detail_fallback)
    }
}
