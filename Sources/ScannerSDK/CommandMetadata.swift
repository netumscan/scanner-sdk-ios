import Foundation
import CNSDK

public enum CommandCode: UInt32, CaseIterable, Sendable {
    case getInfo = 0x0001
    case getBatteryInfo = 0x0002
    case triggerScan = 0x0004
    case stopScan = 0x0005
    case beep = 0x0006
    case disableAckBeep = 0x0007
    case vibrateOn = 0x0008
    case vibrateOff = 0x0009
    case scanEvent = 0x1001
    case ack = 0x7FFE
    case nak = 0x7FFF

    internal var cValue: nsdk_command_code_t {
        nsdk_command_code_t(rawValue: rawValue)
    }
}

public struct CommandDescriptor: Sendable {
    public let text: String
    public let isDangerous: Bool

    public init(text: String, isDangerous: Bool) {
        self.text = text
        self.isDangerous = isDangerous
    }

    internal init(cValue: nsdk_command_descriptor_t) {
        text = stringFromCStringBuffer(cValue.text)
        isDangerous = cValue.dangerous != 0
    }
}

public struct CommandCodeLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_command_code_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct CommandCodeRiskLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public extension CommandCode {
    var localizedRiskLabel: CommandCodeRiskLabel {
        switch self {
        case .getInfo, .getBatteryInfo:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_is_a_read_only_action_and_should_not_trigger_a_danger_confirmation", fallbackDisplayName: "This is a read-only action and should not trigger a danger confirmation.")
        case .beep:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_enables_the_device_acknowledgment_beep_and_changes_feedback_behavior_immediately", fallbackDisplayName: "This enables the device acknowledgment beep and changes feedback behavior immediately.")
        case .disableAckBeep:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_disables_the_device_acknowledgment_beep_and_changes_feedback_behavior_immediately", fallbackDisplayName: "This disables the device acknowledgment beep and changes feedback behavior immediately.")
        case .vibrateOn:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_enables_vibration_feedback_and_changes_feedback_behavior_immediately", fallbackDisplayName: "This enables vibration feedback and changes feedback behavior immediately.")
        case .vibrateOff:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_disables_vibration_feedback_and_changes_feedback_behavior_immediately", fallbackDisplayName: "This disables vibration feedback and changes feedback behavior immediately.")
        default:
            return CommandCodeRiskLabel(localizationKey: "nsdk.command_code_risk.this_command_may_change_device_state_make_sure_the_test_device_can_safely_execute_it", fallbackDisplayName: "This command may change device state. Make sure the test device can safely execute it.")
        }
    }
}

public enum MasterCommandCategory: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case power = 1
    case scanning = 2
    case feedback = 3
    case wireless = 4
    case wired = 5
    case keyboardEncoding = 6
    case dataProcessing = 7
    case module = 8

    internal var cValue: nsdk_master_command_category_t {
        nsdk_master_command_category_t(rawValue: rawValue)
    }
}

public enum MasterCommandSection: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case powerSleep = 1
    case timestamp = 2
    case scanMode = 3
    case scanTiming = 4
    case feedbackAudio = 5
    case feedbackBeepPattern = 6
    case rfTransport = 7
    case rfPairing = 8
    case rfKeyboard = 9
    case bluetoothTransport = 10
    case bluetoothBehavior = 11
    case bluetoothInfo = 12
    case usbInterface = 13
    case usbKeyboard = 14
    case keyModifier = 15
    case charset = 16
    case receiveDevice = 17
    case keyboardLayout = 18
    case dataRule = 19
    case outputFormat = 20
    case replaceRule = 21
    case terminator = 22
    case decoderModule = 23

    internal var cValue: nsdk_master_command_section_t {
        nsdk_master_command_section_t(rawValue: rawValue)
    }
}

public struct MasterCommandMetadata: Sendable {
    public let category: MasterCommandCategory
    public let section: MasterCommandSection

    public init(category: MasterCommandCategory, section: MasterCommandSection) {
        self.category = category
        self.section = section
    }

    internal init(cValue: nsdk_master_command_metadata_t) {
        category = MasterCommandCategory(rawValue: cValue.category.rawValue) ?? .unknown
        section = MasterCommandSection(rawValue: cValue.section.rawValue) ?? .unknown
    }
}

public struct MasterCommandLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_master_command_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct MasterCommandCategoryLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_master_command_category_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct MasterCommandSectionLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_master_command_section_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}
