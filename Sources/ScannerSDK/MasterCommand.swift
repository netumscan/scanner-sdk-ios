import Foundation
import CNSDK

public enum MasterCommand: Int32, CaseIterable, Sendable {
    case readSleepTime = 0x3001
    case powerOff = 0x3002
    case sleepTime1Min = 0x3003
    case sleepTime3Min = 0x3004
    case sleepTime5Min = 0x3005
    case sleepTime10Min = 0x3006
    case sleepTime30Min = 0x3007
    case sleepTime1Hour = 0x3008
    case sleepTime2Hour = 0x3009
    case neverSleep = 0x300A
    case disableTimeStamp = 0x300B
    case enableTimeStamp = 0x300C
    case keyScanModeDefault = 0x300D
    case continueScanMode = 0x300E
    case keyPulseScanMode = 0x300F
    case hostTriggerMode = 0x3010
    case decodeOvertime3S = 0x3011
    case decodeOvertime6S = 0x3012
    case intervalTime500Ms = 0x3013
    case intervalTime1000Ms = 0x3014
    case mute = 0x3015
    case highVolume = 0x3016
    case middleVolume = 0x3017
    case lowVolume = 0x3018
    case highTone = 0x3019
    case lowTone = 0x301A
    case baseConnectBeepPromptToggle = 0x301B
    case readInterfaceSetting = 0x301C
    case switchRf24GTransport = 0x301D
    case rfPair = 0x301E
    case oneToOnePairing = 0x301F
    case oneDongleManyScannersPairing = 0x3020
    case rfDongleCompositeDevice = 0x3021
    case rfDongleVirtualCom = 0x3022
    case rfKeyboardSpeedHigh = 0x3023
    case readKeyboardSpeed = 0x3024
    case rfKeyboardSpeedMedium = 0x3025
    case rfKeyboardSpeedLow = 0x3026
    case sramBufferToggle = 0x3027
    case switchBluetoothTransport = 0x3028
    case bluetoothHid = 0x3029
    case bluetoothSpp = 0x302A
    case bluetoothBle = 0x302B
    case btDongleTransportMode = 0x302C
    case unpairBluetoothHid = 0x302D
    case iosPopupHideKeyboard = 0x302E
    case holdTrigger4Seconds = 0x302F
    case doubleClickTrigger = 0x3030
    case btHidCapsLockIgnore = 0x3031
    case holdTrigger8SecondsSwapRfBt = 0x3032
    case readBtHidDelay = 0x3033
    case btHidDelayHigh = 0x3034
    case btHidDelayValue6 = 0x3035
    case btHidDelayMedium = 0x3036
    case btHidDelayValue18 = 0x3037
    case btHidDelayLow = 0x3038
    case btHidDelayValue30 = 0x3039
    case btConnectedNotSleep = 0x303A
    case switchUsbKeyboardMode = 0x303B
    case switchUsbVirtualComMode = 0x303C
    case usbAutoInterfaceSelectOn = 0x303D
    case usbAutoInterfaceSelectOff = 0x303E
    case usbKeyboardSpeedHigh = 0x303F
    case usbKeyboardSpeedValue4 = 0x3040
    case usbKeyboardSpeedMedium = 0x3041
    case usbKeyboardSpeedValue9 = 0x3042
    case usbKeyboardSpeedLow = 0x3043
    case usbHidMultiKeyOn = 0x3044
    case usbHidMultiKeyOff = 0x3045
    case ctrlKeyPrefixOn = 0x3046
    case combineKeyOff = 0x3047
    case altKeyPrefixOn = 0x3048
    case normalKeyConfig2 = 0x3049
    case caseStrategyNormal = 0x304A
    case caseStrategySwap = 0x304B
    case caseStrategyUpper = 0x304C
    case caseStrategyLower = 0x304D
    case numLockOff = 0x304E
    case numLockOn = 0x304F
    case readCurrentCharset = 0x3050
    case charsetAuto = 0x3051
    case charsetGbk = 0x3052
    case charsetUtf8Word = 0x3053
    case charsetIso8859 = 0x3054
    case charsetNormal = 0x3055
    case charsetUtf8Txt = 0x3056
    case readCurrentReceiveDevice = 0x3057
    case receiveDeviceWindows = 0x3058
    case receiveDeviceMacOsIos = 0x3059
    case receiveDeviceAndroid = 0x305A
    case readKeyboardLayout = 0x305B
    case keyboardLayoutEN = 0x305C
    case keyboardLayoutFR = 0x305D
    case keyboardLayoutGE = 0x305E
    case keyboardLayoutIT = 0x305F
    case keyboardLayoutPT = 0x3060
    case keyboardLayoutES = 0x3061
    case keyboardLayoutTK = 0x3062
    case keyboardLayoutTF = 0x3063
    case keyboardLayoutUK = 0x3064
    case keyboardLayoutCS = 0x3065
    case keyboardLayoutCY = 0x3066
    case keyboardLayoutHU = 0x3067
    case keyboardLayoutFB = 0x3068
    case keyboardLayoutPB = 0x3069
    case keyboardLayoutFC = 0x306A
    case keyboardLayoutHR = 0x306B
    case keyboardLayoutSK = 0x306C
    case keyboardLayoutSQ = 0x306D
    case keyboardLayoutDA = 0x306E
    case keyboardLayoutFI = 0x306F
    case keyboardLayoutEL = 0x3070
    case keyboardLayoutNL = 0x3071
    case keyboardLayoutNO = 0x3072
    case keyboardLayoutPL = 0x3073
    case keyboardLayoutSR = 0x3074
    case keyboardLayoutSL = 0x3075
    case keyboardLayoutSV = 0x3076
    case keyboardLayoutDS = 0x3077
    case keyboardLayoutJP = 0x3078
    case keyboardLayoutTH = 0x3079
    case keyboardLayoutAG = 0x307A
    case keyboardLayoutRU = 0x307B
    case scanOperation1 = 0x307C
    case scanOperation2 = 0x307D
    case clearAllSuffix = 0x307E
    case clearAllPrefix = 0x307F
    case scanOperation5 = 0x3080
    case scanOperation6 = 0x3081
    case scanOperation7 = 0x3082
    case scanOperation8 = 0x3083
    case numericCode0 = 0x3084
    case numericCode1 = 0x3085
    case numericCode2 = 0x3086
    case numericCode3 = 0x3087
    case numericCode4 = 0x3088
    case numericCode5 = 0x3089
    case numericCode6 = 0x308A
    case numericCode7 = 0x308B
    case numericCode8 = 0x308C
    case numericCode9 = 0x308D
    case numericCodeA = 0x308E
    case numericCodeB = 0x308F
    case numericCodeC = 0x3090
    case numericCodeD = 0x3091
    case numericCodeE = 0x3092
    case numericCodeF = 0x3093
    case clearOutputFormat = 0x3094
    case enableSuffixOutput = 0x3095
    case enablePrefixOutput = 0x3096
    case enableHideEndOutput = 0x3097
    case enableHideMiddleOutput = 0x3098
    case enableHideStartOutput = 0x3099
    case readReplaceSet = 0x309A
    case clearReplaceSet = 0x309B
    case extraTerminalNone = 0x309C
    case extraTerminalCr = 0x309D
    case extraTerminalTab = 0x309E
    case extraTerminalCrLf = 0x309F
    case extraTerminalLf = 0x30A0
    case readBtFirmwareVersion = 0x30A1
    case readBtName = 0x30A2
    case readBtAddress = 0x30A3
    case rebootBt = 0x30A4
    case restoreBtFactorySettings = 0x30A5
    case disconnectCurrentBt = 0x30A6
    case readDecoderModule = 0x30A7
    case setDecoderModule0 = 0x30A8
    case setDecoderModule1 = 0x30A9
    case setDecoderModule2 = 0x30AA
    case setDecoderModule3 = 0x30AB
    case setDecoderModule4 = 0x30AC
    case setDecoderModule5 = 0x30AD
    case immediateScan1S = 0x30AE
    case immediateScan2S = 0x30AF
    case immediateScan3S = 0x30B0
    case immediateScan4S = 0x30B1
    case immediateScan5S = 0x30B2
    case immediateScan6S = 0x30B3
    case immediateScan7S = 0x30B4
    case usbKeyboardSpeedLowDelay = 0x30B5
    case sdkBeepB0 = 0x30B6
    case sdkBeepB1 = 0x30B7
    case sdkBeepB2 = 0x30B8
    case sdkBeepB3 = 0x30B9
    case sdkBeepB4 = 0x30BA
    case sdkBeepB5 = 0x30BB
    case sdkBeepB6 = 0x30BC
    case sdkBeepB7 = 0x30BD
    case sdkBeepB8 = 0x30BE
    case sdkBeepB9 = 0x30BF
    case sdkBeepBColon = 0x30C0
    case sdkBeepBSemicolon = 0x30C1
    case sdkBeepBLessThan = 0x30C2
    case sdkBeepBEquals = 0x30C3
    case sdkBeepBGreaterThan = 0x30C4
    case sdkBeepBQuestion = 0x30C5
    case sdkBeepBAt = 0x30C6
    case sdkBeepBA = 0x30C7
    case sdkBeepBB = 0x30C8
    case sdkBeepBC = 0x30C9
    case sdkBeepBD = 0x30CA
    case sdkBeepBE = 0x30CB
    case sdkBeepBF = 0x30CC
    case sdkBeepBG = 0x30CD
    case sdkBeepBH = 0x30CE
    case sdkBeepBI = 0x30CF
    case sdkBeepBJ = 0x30D0

    internal var cValue: nsdk_master_command_id_t {
        nsdk_master_command_id_t(rawValue)
    }
}

public struct MasterCommandRiskLabel: Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public extension MasterCommand {
    var localizedRiskLabel: MasterCommandRiskLabel {
        switch self {
        case .powerOff:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.the_device_may_sleep_immediately_or_disconnect", fallbackDisplayName: "The device may sleep immediately or disconnect.")
        case .switchRf24GTransport,
             .switchBluetoothTransport,
             .bluetoothHid,
             .bluetoothSpp,
             .bluetoothBle,
             .switchUsbKeyboardMode,
             .switchUsbVirtualComMode:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_changes_the_interface_or_transport_mode_and_may_interrupt_the_current_ble_link", fallbackDisplayName: "This changes the interface or transport mode and may interrupt the current BLE link.")
        case .usbAutoInterfaceSelectOn:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_enables_wired_wireless_auto_selection_the_device_may_prefer_wireless_later_and_the_current", fallbackDisplayName: "This enables wired/wireless auto selection. The device may prefer wireless later and the current link may drop.")
        case .usbAutoInterfaceSelectOff:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_disables_wired_wireless_auto_selection_the_device_will_reboot_disconnect_ble_and_fall_back", fallbackDisplayName: "This disables wired/wireless auto selection. The device will reboot, disconnect BLE, and fall back to wired mode.")
        case .rfPair,
             .oneToOnePairing,
             .oneDongleManyScannersPairing,
             .unpairBluetoothHid:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_changes_pairing_state_and_may_invalidate_the_current_connection", fallbackDisplayName: "This changes pairing state and may invalidate the current connection.")
        case .holdTrigger8SecondsSwapRfBt:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_changes_rf_bt_switching_behavior_and_may_alter_the_current_test_state", fallbackDisplayName: "This changes RF/BT switching behavior and may alter the current test state.")
        default:
            return MasterCommandRiskLabel(localizationKey: "nsdk.master_command_risk.this_is_a_high_risk_operation_make_sure_the_test_device_can_safely_execute_it", fallbackDisplayName: "This is a high-risk operation. Make sure the test device can safely execute it.")
        }
    }
}
