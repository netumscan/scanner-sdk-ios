import Foundation
import CNSDK

public enum BasicDeviceCommand: UInt32, CaseIterable, Sendable {
    case getVersion = 1
    case factoryReset = 2
    case writeCustomDefaults = 3
    case restoreCustomDefaults = 4
    case normalMode = 5
    case storeMode = 6
    case uploadMemoryData = 7
    case getMemoryBarcodeCount = 8
    case uploadMemoryDataAndClear = 9
    case getMemoryUsage = 10
    case clearMemory = 11
    case autoStoreModeOff = 12
    case autoStoreModeOn = 13

    internal var cValue: nsdk_basic_device_command_t {
        nsdk_basic_device_command_t(rawValue: rawValue)
    }
}

public struct BasicDeviceCommandLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }

    internal init(cValue: nsdk_basic_device_command_label_t) {
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public struct BasicDeviceCommandRiskLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public extension BasicDeviceCommand {
    var localizedRiskLabel: BasicDeviceCommandRiskLabel {
        switch self {
        case .factoryReset:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_restores_factory_defaults_and_may_erase_the_current_configuration", fallbackDisplayName: "This restores defaults. If custom defaults exist, those values are restored; otherwise factory defaults are restored.")
        case .writeCustomDefaults:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_writes_the_current_configuration_as_the_new_custom_defaults", fallbackDisplayName: "This writes the current configuration as the new custom defaults.")
        case .restoreCustomDefaults:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_restores_the_previously_saved_custom_defaults", fallbackDisplayName: "This clears custom defaults and restores factory defaults.")
        case .storeMode, .normalMode:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_changes_the_device_operating_mode_and_may_immediately_alter_current_behavior", fallbackDisplayName: "This changes the device operating mode and may immediately alter current behavior.")
        case .uploadMemoryDataAndClear, .clearMemory:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_affects_stored_barcode_data_on_the_device_and_may_be_irreversible", fallbackDisplayName: "This affects stored barcode data on the device and may be irreversible.")
        case .autoStoreModeOff, .autoStoreModeOn:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_changes_automatic_storage_behavior", fallbackDisplayName: "This changes automatic storage behavior.")
        default:
            return BasicDeviceCommandRiskLabel(localizationKey: "nsdk.basic_device_command_risk.this_is_a_high_risk_operation_make_sure_the_test_device_can_safely_execute_it", fallbackDisplayName: "This is a high-risk operation. Make sure the test device can safely execute it.")
        }
    }
}
