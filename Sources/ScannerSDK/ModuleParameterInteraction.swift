import Foundation
import CNSDK

public enum ModuleParameterNumericInputKind: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case tenthsSeconds = 1
    case uint8Decimal = 2
    case uint16Milliseconds = 3
}

public enum ModuleParameterKind: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case bool = 1
    case enumeration = 2
    case uint8 = 3
    case uint16 = 4
    case bytesAscii = 5
    case action = 6
    case complex = 7
    case custom = 8
    case object = 9

    internal var cValue: nsdk_module_parameter_ui_kind_t {
        nsdk_module_parameter_ui_kind_t(rawValue)
    }
}

public struct ModuleParameterQuickValue: Sendable {
    public let payloadHex: String
    public let localizationKey: String
    public let fallbackDisplayName: String

    internal init(cValue: nsdk_module_parameter_quick_value_t) {
        payloadHex = stringFromCStringBuffer(cValue.payload_hex)
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct ModuleParameterNumericInputSpec: Sendable {
    public let kind: ModuleParameterNumericInputKind
    public let localizationKey: String
    public let fallbackDisplayName: String
    public let minValue: Int32
    public let maxValue: Int32
    public let stepHintKey: String
    public let stepHintFallback: String

    internal init(cValue: nsdk_module_parameter_numeric_input_spec_t) {
        kind = ModuleParameterNumericInputKind(rawValue: cValue.kind.rawValue) ?? .unknown
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
        minValue = cValue.min_value
        maxValue = cValue.max_value
        stepHintKey = stringFromCStringBuffer(cValue.step_hint_key)
        stepHintFallback = stringFromCStringBuffer(cValue.step_hint_fallback)
    }
}

public struct ModuleParameterBooleanPayloadPair: Sendable {
    public let offPayloadHex: String
    public let onPayloadHex: String

    internal init(offPayloadHex: String, onPayloadHex: String) {
        self.offPayloadHex = offPayloadHex
        self.onPayloadHex = onPayloadHex
    }

    internal init(cValue: nsdk_module_parameter_boolean_payload_pair_t) {
        offPayloadHex = stringFromCStringBuffer(cValue.off_payload_hex)
        onPayloadHex = stringFromCStringBuffer(cValue.on_payload_hex)
    }
}

public struct ModuleParameterEnumLabel: Sendable {
    public let rawLabel: String
    public let localizationKey: String
    public let fallbackDisplayName: String

    internal init(rawLabel: String, localizationKey: String, fallbackDisplayName: String) {
        self.rawLabel = rawLabel
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_module_parameter_enum_label_t) {
        rawLabel = stringFromCStringBuffer(cValue.raw_label)
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct ModuleParameterKindLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    internal init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_module_parameter_kind_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct ModuleParameterTitleLabel: Sendable {
    public let rawTitle: String
    public let localizationKey: String
    public let fallbackDisplayName: String

    internal init(rawTitle: String, localizationKey: String, fallbackDisplayName: String) {
        self.rawTitle = rawTitle
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_module_parameter_title_label_t) {
        rawTitle = stringFromCStringBuffer(cValue.raw_title)
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}
