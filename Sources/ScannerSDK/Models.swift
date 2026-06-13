import Foundation
import CNSDK

public struct DiscoveredDevice: Sendable {
    public let deviceId: String
    public let name: String
    public let transportType: TransportType
    public let modelId: DeviceModelId
    public let matchReason: String?
    public let rssi: Int?

    public init(
        deviceId: String,
        name: String,
        transportType: TransportType,
        modelId: DeviceModelId = .unknown,
        matchReason: String? = nil,
        rssi: Int? = nil
    ) {
        self.deviceId = deviceId
        self.name = name
        self.transportType = transportType
        self.modelId = modelId
        self.matchReason = matchReason
        self.rssi = rssi
    }
}

public struct ScannerInfo: Sendable {
    public let deviceId: String
    public let name: String
    public let serialNumber: String
    public let firmwareVersion: String
    public let hardwareVersion: String
    public let manufacturer: String
    public let versionFormatFamily: String
    public let versionBootCode: String
    public let versionSeriesCode: String
    public let versionTransportCode: String
    public let versionTransportSuffix: String
    public let versionWirelessCode: String
    public let versionBluetoothCode: String
    public let versionChipsetCode: String
    public let versionChipsetSuffix: String
    public let versionReleaseCode: String
    public let versionExtensionCode: String
}

public enum DeviceModelId: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case nt91 = 1
    case nt1228bc = 4
    case c750 = 10
    case cs7501 = 12
    case cs8501 = 13
    case cs9501 = 14
    case c740 = 15
}

public enum CommandSetKind: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case masterOnly = 1
    case moduleOnly = 2
    case masterWithModuleInfo = 3

    public var localizedLabel: CommandSetKindLabel {
        switch self {
        case .unknown:
            return CommandSetKindLabel(localizationKey: "nsdk.command_set_kind.unknown_command_set", fallbackDisplayName: "Unknown command set")
        case .masterOnly:
            return CommandSetKindLabel(localizationKey: "nsdk.command_set_kind.scanner_master", fallbackDisplayName: "Scanner master")
        case .moduleOnly:
            return CommandSetKindLabel(localizationKey: "nsdk.command_set_kind.module_only", fallbackDisplayName: "Module only")
        case .masterWithModuleInfo:
            return CommandSetKindLabel(localizationKey: "nsdk.command_set_kind.master_with_module_info", fallbackDisplayName: "Master with module info")
        }
    }
}

public enum DeviceFormFactor: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case master = 1
    case masterWithModule = 2
    case singleModule = 3

    public var localizedLabel: DeviceFormFactorLabel {
        switch self {
        case .unknown:
            return DeviceFormFactorLabel(localizationKey: "nsdk.device_form_factor.unknown_form_factor", fallbackDisplayName: "Unknown form factor")
        case .master:
            return DeviceFormFactorLabel(localizationKey: "nsdk.device_form_factor.scanner_master", fallbackDisplayName: "Scanner master")
        case .masterWithModule:
            return DeviceFormFactorLabel(localizationKey: "nsdk.device_form_factor.master_with_module", fallbackDisplayName: "Master with module")
        case .singleModule:
            return DeviceFormFactorLabel(localizationKey: "nsdk.device_form_factor.single_module", fallbackDisplayName: "Single module")
        }
    }
}

public enum SupportStatus: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case implemented = 1
    case codeOnly = 2
    case verified = 3

    public var localizedLabel: SupportStatusLabel {
        switch self {
        case .unknown:
            return SupportStatusLabel(localizationKey: "nsdk.support_status.unknown", fallbackDisplayName: "Unknown")
        case .implemented:
            return SupportStatusLabel(localizationKey: "nsdk.support_status.implemented", fallbackDisplayName: "Implemented")
        case .codeOnly:
            return SupportStatusLabel(localizationKey: "nsdk.support_status.code_only", fallbackDisplayName: "Code only")
        case .verified:
            return SupportStatusLabel(localizationKey: "nsdk.support_status.verified", fallbackDisplayName: "Verified")
        }
    }
}

public struct CommandSetKindLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct DeviceFormFactorLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct SupportStatusLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct DeviceCapabilitySummary: Sendable {
    public let modelId: DeviceModelId
    public let modelName: String
    public let defaultCommandSet: CommandSetKind
    public let formFactor: DeviceFormFactor
    public let moduleFamily: ModuleFamily
    public let supportsBasicDeviceCommands: Bool
    public let supportsMasterCommands: Bool
    public let supportsNativeModuleCommands: Bool
    public let supportsModuleCommandBridge: Bool
    public let supportsModuleCommands: Bool
    public let supportsScannerMaster: Bool
    public let supportsModulePassthrough: Bool
    public let supportStatus: SupportStatus

    public init(
        modelId: DeviceModelId,
        modelName: String,
        defaultCommandSet: CommandSetKind,
        formFactor: DeviceFormFactor,
        moduleFamily: ModuleFamily,
        supportsBasicDeviceCommands: Bool,
        supportsMasterCommands: Bool,
        supportsNativeModuleCommands: Bool = false,
        supportsModuleCommandBridge: Bool = false,
        supportsModuleCommands: Bool,
        supportsScannerMaster: Bool,
        supportsModulePassthrough: Bool,
        supportStatus: SupportStatus
    ) {
        self.modelId = modelId
        self.modelName = modelName
        self.defaultCommandSet = defaultCommandSet
        self.formFactor = formFactor
        self.moduleFamily = moduleFamily
        self.supportsBasicDeviceCommands = supportsBasicDeviceCommands
        self.supportsMasterCommands = supportsMasterCommands
        self.supportsNativeModuleCommands = supportsNativeModuleCommands
        self.supportsModuleCommandBridge = supportsModuleCommandBridge
        self.supportsModuleCommands = supportsModuleCommands
        self.supportsScannerMaster = supportsScannerMaster
        self.supportsModulePassthrough = supportsModulePassthrough
        self.supportStatus = supportStatus
    }

    public var displayModelName: String {
        modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? String(describing: modelId) : modelName
    }

    public var displaySummary: String {
        "\(displayModelName) / \(defaultCommandSet) / scannerMaster=\(supportsScannerMaster) / nativeModule=\(supportsNativeModuleCommands) / moduleBridge=\(supportsModuleCommandBridge) / modulePassthrough=\(supportsModulePassthrough) / status=\(supportStatus)"
    }
}

public struct SessionOperationSupportSummary: Sendable {
    public let supportsRefreshInfo: Bool
    public let supportsInitializeSession: Bool
    public let supportsGetBatteryInfo: Bool
    public let supportsExecuteBasicDeviceCommands: Bool
    public let supportsExecuteTextCommands: Bool
    public let supportsExecuteDataRuleCommands: Bool
    public let supportsDefaultModuleCommandProbe: Bool
    public let supportsTriggerScan: Bool
    public let supportsBeep: Bool
    public let supportsDisableAckBeep: Bool
    public let supportsVibrateOn: Bool
    public let supportsVibrateOff: Bool

    public init(
        supportsRefreshInfo: Bool,
        supportsInitializeSession: Bool,
        supportsGetBatteryInfo: Bool,
        supportsExecuteBasicDeviceCommands: Bool,
        supportsExecuteTextCommands: Bool,
        supportsExecuteDataRuleCommands: Bool,
        supportsDefaultModuleCommandProbe: Bool,
        supportsTriggerScan: Bool,
        supportsBeep: Bool,
        supportsDisableAckBeep: Bool,
        supportsVibrateOn: Bool,
        supportsVibrateOff: Bool
    ) {
        self.supportsRefreshInfo = supportsRefreshInfo
        self.supportsInitializeSession = supportsInitializeSession
        self.supportsGetBatteryInfo = supportsGetBatteryInfo
        self.supportsExecuteBasicDeviceCommands = supportsExecuteBasicDeviceCommands
        self.supportsExecuteTextCommands = supportsExecuteTextCommands
        self.supportsExecuteDataRuleCommands = supportsExecuteDataRuleCommands
        self.supportsDefaultModuleCommandProbe = supportsDefaultModuleCommandProbe
        self.supportsTriggerScan = supportsTriggerScan
        self.supportsBeep = supportsBeep
        self.supportsDisableAckBeep = supportsDisableAckBeep
        self.supportsVibrateOn = supportsVibrateOn
        self.supportsVibrateOff = supportsVibrateOff
    }

    public var displaySummary: String {
        "refreshInfo=\(supportsRefreshInfo) / initializeSession=\(supportsInitializeSession) / getBatteryInfo=\(supportsGetBatteryInfo) / basicDeviceCommands=\(supportsExecuteBasicDeviceCommands) / textCommands=\(supportsExecuteTextCommands) / dataRuleCommands=\(supportsExecuteDataRuleCommands) / defaultModuleProbe=\(supportsDefaultModuleCommandProbe) / triggerScan=\(supportsTriggerScan) / beep=\(supportsBeep) / disableAckBeep=\(supportsDisableAckBeep) / vibrateOn=\(supportsVibrateOn) / vibrateOff=\(supportsVibrateOff)"
    }
}

public struct DeviceModelProfile: Sendable {
    public let capability: DeviceCapabilitySummary
    public let bleServiceUuids: [String]
    public let bleNameHints: [String]
    public let usbVendorId: Int?
    public let usbProductIds: [Int]
    public let usbInterfaceNumber: Int?
    public let usbHidReportId: Int?
}

public struct BatteryInfo: Sendable {
    public let rawText: String
    public let voltageText: String
    public let percent: Int
}

public struct ScanEvent: Sendable {
    public let timestampMs: UInt64
    public let barcodeType: Int32
    public let text: String
    public let textBytes: Data
    public let rawBytes: Data
}

public enum TransportFailureCode: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case platformStatusError = 1
    case connectionTimeout = 2
    case gattFailure = 3
    case serviceDiscoveryStartFailed = 4
    case serviceDiscoveryFailed = 5
    case notifyServiceMissing = 6
    case notifyCharacteristicMissing = 7
    case setNotificationFailed = 8
    case notifyDescriptorMissing = 9
    case notifyDescriptorWriteFailed = 10

    public var localizedLabel: TransportFailureCodeLabel {
        switch self {
        case .serviceDiscoveryStartFailed:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.service_discovery_did_not_start", fallbackDisplayName: "Service discovery did not start")
        case .serviceDiscoveryFailed:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.service_discovery_failed", fallbackDisplayName: "Service discovery failed")
        case .notifyServiceMissing:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.notify_service_missing", fallbackDisplayName: "Notify service missing")
        case .notifyCharacteristicMissing:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.notify_characteristic_missing", fallbackDisplayName: "Notify characteristic missing")
        case .setNotificationFailed:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.enabling_notifications_failed", fallbackDisplayName: "Enabling notifications failed")
        case .notifyDescriptorMissing:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.notify_descriptor_missing", fallbackDisplayName: "Notify descriptor missing")
        case .notifyDescriptorWriteFailed:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.notify_descriptor_write_failed", fallbackDisplayName: "Notify descriptor write failed")
        case .connectionTimeout:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.connection_timeout", fallbackDisplayName: "Connection timeout")
        case .gattFailure:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.platform_gatt_failure", fallbackDisplayName: "Platform GATT failure")
        case .platformStatusError:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.platform_connection_status_error", fallbackDisplayName: "Platform connection status error")
        case .unknown:
            return TransportFailureCodeLabel(localizationKey: "nsdk.transport_failure_code.unknown_transport_error", fallbackDisplayName: "Unknown transport error")
        }
    }

    public var localizedStatusLabel: TransportFailureStatusLabel {
        switch self {
        case .serviceDiscoveryStartFailed,
             .serviceDiscoveryFailed,
             .notifyServiceMissing,
             .notifyCharacteristicMissing,
             .setNotificationFailed,
             .notifyDescriptorMissing,
             .notifyDescriptorWriteFailed:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_setup_failed", fallbackDisplayName: "Connection setup failed")
        case .connectionTimeout:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_timed_out", fallbackDisplayName: "Connection timed out")
        default:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_failed", fallbackDisplayName: "Connection failed")
        }
    }
}

public struct TransportFailureCodeLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct TransportFailureStatusLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public enum BleTransportIssue: UInt32, CaseIterable, Sendable {
    case unknown = 0
    case serviceDiscoveryStartFailed = 1
    case serviceDiscoveryFailed = 2
    case notifyServiceMissing = 3
    case notifyCharacteristicMissing = 4
    case setNotificationFailed = 5
    case notifyDescriptorMissing = 6
    case notifyDescriptorWriteFailed = 7
    case connectionTimeout = 8
    case gattFailure = 9
    case platformStatusError = 10

    public var localizedLabel: BleTransportIssueLabel {
        switch self {
        case .serviceDiscoveryStartFailed:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.service_discovery_did_not_start", fallbackDisplayName: "Service discovery did not start")
        case .serviceDiscoveryFailed:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.service_discovery_failed", fallbackDisplayName: "Service discovery failed")
        case .notifyServiceMissing:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.notify_service_missing", fallbackDisplayName: "Notify service missing")
        case .notifyCharacteristicMissing:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.notify_characteristic_missing", fallbackDisplayName: "Notify characteristic missing")
        case .setNotificationFailed:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.enabling_notifications_failed", fallbackDisplayName: "Enabling notifications failed")
        case .notifyDescriptorMissing:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.notify_descriptor_missing", fallbackDisplayName: "Notify descriptor missing")
        case .notifyDescriptorWriteFailed:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.notify_descriptor_write_failed", fallbackDisplayName: "Notify descriptor write failed")
        case .connectionTimeout:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.connection_timeout", fallbackDisplayName: "Connection timeout")
        case .gattFailure:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.platform_gatt_failure", fallbackDisplayName: "Platform GATT failure")
        case .platformStatusError:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.platform_connection_status_error", fallbackDisplayName: "Platform connection status error")
        case .unknown:
            return BleTransportIssueLabel(localizationKey: "nsdk.ble_transport_issue.unknown_ble_transport_issue", fallbackDisplayName: "Unknown BLE transport issue")
        }
    }
}

public struct BleTransportIssueLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public enum DiscoveryFailureCode: UInt32, CaseIterable, Sendable {
    case bleAdapterDisabled = 0
    case bleScannerUnavailable = 1
    case bleFilteredScanFailed = 2
    case bleFilteredScanFallbackFailed = 3
    case bleUnfilteredScanFailed = 4

    public var localizedLabel: DiscoveryFailureCodeLabel {
        switch self {
        case .bleAdapterDisabled:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.bluetooth_disabled", fallbackDisplayName: "Bluetooth disabled")
        case .bleScannerUnavailable:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.scanner_unavailable", fallbackDisplayName: "Scanner unavailable")
        case .bleFilteredScanFailed:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.filtered_scan_failed", fallbackDisplayName: "Filtered scan failed")
        case .bleFilteredScanFallbackFailed:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.filtered_scan_fallback_failed", fallbackDisplayName: "Filtered scan fallback failed")
        case .bleUnfilteredScanFailed:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.fallback_scan_failed", fallbackDisplayName: "Fallback scan failed")
        }
    }
}

public struct DiscoveryFailureCodeLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public enum BleScanIssue: UInt32, CaseIterable, Sendable {
    case alreadyStarted = 0
    case registrationFailed = 1
    case internalError = 2
    case featureUnsupported = 3
    case outOfHardwareResources = 4
    case throttled = 5
    case unknown = 6

    public var localizedLabel: BleScanIssueLabel {
        switch self {
        case .alreadyStarted:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.scan_already_started", fallbackDisplayName: "Scan already started")
        case .registrationFailed:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.scanner_registration_failed", fallbackDisplayName: "Scanner registration failed")
        case .internalError:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.platform_internal_error", fallbackDisplayName: "Platform internal error")
        case .featureUnsupported:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.scan_feature_unsupported", fallbackDisplayName: "Scan feature unsupported")
        case .outOfHardwareResources:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.out_of_hardware_resources", fallbackDisplayName: "Out of hardware resources")
        case .throttled:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.scan_requests_throttled", fallbackDisplayName: "Scan requests throttled")
        case .unknown:
            return BleScanIssueLabel(localizationKey: "nsdk.ble_scan_issue.unknown_platform_scan_error", fallbackDisplayName: "Unknown platform scan error")
        }
    }
}

public struct BleScanIssueLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct SessionFailure: Sendable {
    public let sessionHandle: UInt64?
    public let deviceId: String
    public let transportType: TransportType
    public let code: TransportFailureCode
    public let message: String
    public let bleTransportIssue: BleTransportIssue?
    public let platformErrorCode: Int32?
}

public struct SessionInitializationStageEvent: Sendable {
    public let sessionHandle: UInt64
    public let deviceId: String
    public let selectedModelId: DeviceModelId
    public let stage: SessionInitializationStage
    public let timestampMs: UInt64
    public let traceId: UInt64
    public let success: Bool
    public let errorCode: Int32
    public let message: String?
}

public struct DiscoveryFailure: Sendable {
    public let transportType: TransportType
    public let code: DiscoveryFailureCode
    public let message: String
    public let bleScanIssue: BleScanIssue?
    public let platformErrorCode: Int32?
    public let recoverable: Bool

    public var localizedStatusLabel: DiscoveryFailureStatusLabel {
        if code == .bleAdapterDisabled {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.bluetooth_disabled", fallbackDisplayName: "Bluetooth disabled")
        }
        if code == .bleScannerUnavailable {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.scanner_unavailable", fallbackDisplayName: "Scanner unavailable")
        }
        if bleScanIssue == .featureUnsupported {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.discovery_feature_unsupported", fallbackDisplayName: "Discovery feature unsupported")
        }
        if bleScanIssue == .outOfHardwareResources {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.ble_scan_resources_exhausted", fallbackDisplayName: "BLE scan resources exhausted")
        }
        if bleScanIssue == .throttled {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.discovery_throttled", fallbackDisplayName: "Discovery throttled")
        }
        if recoverable {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.discovery_downgraded_to_fallback_mode", fallbackDisplayName: "Discovery downgraded to fallback mode")
        }
        return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.discovery_failed", fallbackDisplayName: "Discovery failed")
    }
}

extension DiscoveryFailureCode {
    internal init(cValue: nsdk_discovery_failure_code_t) {
        self = DiscoveryFailureCode(rawValue: cValue.rawValue) ?? .bleScannerUnavailable
    }
}

extension BleScanIssue {
    internal init(cValue: nsdk_ble_scan_issue_t) {
        self = BleScanIssue(rawValue: cValue.rawValue) ?? .unknown
    }
}

extension DiscoveryFailure {
    internal init(cValue: nsdk_discovery_failure_t) {
        transportType = TransportType(rawValue: cValue.transport.rawValue) ?? .bleGatt
        code = DiscoveryFailureCode(cValue: cValue.code)
        message = stringFromCStringBuffer(cValue.message)
        bleScanIssue = cValue.ble_issue_available != 0 ? BleScanIssue(cValue: cValue.ble_issue) : nil
        platformErrorCode = cValue.platform_error_available != 0 ? cValue.platform_error : nil
        recoverable = cValue.recoverable != 0
    }
}

public struct DiscoveryFailureStatusLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct CommandResponse: Sendable {
    public let textBytes: Data
    public let textFullSize: Int
    public let textBytesComplete: Bool
    public let rawBytes: Data
    public let acknowledged: Bool
    public let recordCount: Int
    public let recordBytes: [Data]
    public let recordsComplete: Bool
    public let modulePayloadBytes: Data
    public let modulePayloadFullSize: Int
    public let moduleParameterID: Int
    public let moduleParameterValueBytes: Data
    public let moduleParameterValueFullSize: Int
    public let moduleParameterValueAvailable: Bool

    public init(
        textBytes: Data,
        textFullSize: Int? = nil,
        textBytesComplete: Bool? = nil,
        rawBytes: Data,
        acknowledged: Bool,
        recordCount: Int,
        recordBytes: [Data],
        recordsComplete: Bool,
        modulePayloadBytes: Data = Data(),
        modulePayloadFullSize: Int? = nil,
        moduleParameterID: Int = 0,
        moduleParameterValueBytes: Data = Data(),
        moduleParameterValueFullSize: Int? = nil,
        moduleParameterValueAvailable: Bool = false
    ) {
        let resolvedTextFullSize = textFullSize ?? textBytes.count
        let resolvedModulePayloadFullSize = modulePayloadFullSize ?? modulePayloadBytes.count
        let resolvedModuleParameterValueFullSize = moduleParameterValueFullSize ?? moduleParameterValueBytes.count
        self.textBytes = textBytes
        self.textFullSize = resolvedTextFullSize
        self.textBytesComplete = textBytesComplete ?? (textBytes.count >= resolvedTextFullSize)
        self.rawBytes = rawBytes
        self.acknowledged = acknowledged
        self.recordCount = recordCount
        self.recordBytes = recordBytes
        self.recordsComplete = recordsComplete
        self.modulePayloadBytes = modulePayloadBytes
        self.modulePayloadFullSize = resolvedModulePayloadFullSize
        self.moduleParameterID = moduleParameterID
        self.moduleParameterValueBytes = moduleParameterValueBytes
        self.moduleParameterValueFullSize = resolvedModuleParameterValueFullSize
        self.moduleParameterValueAvailable = moduleParameterValueAvailable
    }

    public var textTruncated: Bool {
        !textBytesComplete
    }

    public var modulePayloadComplete: Bool {
        modulePayloadBytes.count >= modulePayloadFullSize
    }

    public var moduleParameterValueComplete: Bool {
        moduleParameterValueBytes.count >= moduleParameterValueFullSize
    }

    public var moduleParameterValueTruncated: Bool {
        moduleParameterValueAvailable && !moduleParameterValueComplete
    }

    public var text: String {
        decodeText(String.Encoding.utf8)
    }

    public var records: [String] {
        decodeRecords(String.Encoding.utf8)
    }

    public var rawHex: String {
        rawBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    public func decodeText(_ encoding: String.Encoding) -> String {
        String(data: textBytes, encoding: encoding) ?? String(decoding: textBytes, as: UTF8.self)
    }

    public func decodeText(_ charset: ScanTextCharset) -> String {
        decodeText(charset.encoding)
    }

    public func decodeRecords(_ encoding: String.Encoding) -> [String] {
        recordBytes.map { data in
            String(data: data, encoding: encoding) ?? String(decoding: data, as: UTF8.self)
        }
    }

    public func decodeRecords(_ charset: ScanTextCharset) -> [String] {
        decodeRecords(charset.encoding)
    }
}
