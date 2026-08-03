import Foundation
import CNSDK

public struct DiscoveredDevice: Sendable {
    public let deviceId: String
    public let name: String
    public let transportType: TransportType
    public let modelKey: String
    public let matchReason: String?
    public let rssi: Int?

    public init(
        deviceId: String,
        name: String,
        transportType: TransportType,
        modelKey: String = "",
        matchReason: String? = nil,
        rssi: Int? = nil
    ) {
        self.deviceId = deviceId
        self.name = name
        self.transportType = transportType
        self.modelKey = modelKey
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
    public let bluetoothName: String
    public let bluetoothFirmwareVersion: String
}

public enum DeviceSupportStatus: Int32, CaseIterable, Sendable {
    case unknown = 0
    case codeOnly = 1
    case verified = 2

    public var localizedLabel: DeviceSupportStatusLabel {
        switch self {
        case .unknown:
            return DeviceSupportStatusLabel(localizationKey: "nsdk.support_status.unknown", fallbackDisplayName: "Unknown")
        case .codeOnly:
            return DeviceSupportStatusLabel(localizationKey: "nsdk.support_status.code_only", fallbackDisplayName: "Code only")
        case .verified:
            return DeviceSupportStatusLabel(localizationKey: "nsdk.support_status.verified", fallbackDisplayName: "Verified")
        }
    }
}

public struct DeviceSupportStatusLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}

public struct DeviceCapabilitySummary: Sendable {
    public let modelKey: String
    public let modelName: String
    public let supportsScanControl: Bool
    public let supportsDeviceCommands: Bool
    public let supportsSettingsRead: Bool
    public let supportsSettingsWrite: Bool
    public let supportsDataRules: Bool
    public let supportsBattery: Bool
    public let supportStatus: DeviceSupportStatus

    public init(
        modelKey: String,
        modelName: String,
        supportsScanControl: Bool,
        supportsDeviceCommands: Bool,
        supportsSettingsRead: Bool,
        supportsSettingsWrite: Bool,
        supportsDataRules: Bool,
        supportsBattery: Bool,
        supportStatus: DeviceSupportStatus
    ) {
        self.modelKey = modelKey
        self.modelName = modelName
        self.supportsScanControl = supportsScanControl
        self.supportsDeviceCommands = supportsDeviceCommands
        self.supportsSettingsRead = supportsSettingsRead
        self.supportsSettingsWrite = supportsSettingsWrite
        self.supportsDataRules = supportsDataRules
        self.supportsBattery = supportsBattery
        self.supportStatus = supportStatus
    }

    public var displayModelName: String {
        modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? modelKey : modelName
    }

    public var displaySummary: String {
        "\(displayModelName) / scanControl=\(supportsScanControl) / settingsRead=\(supportsSettingsRead) / settingsWrite=\(supportsSettingsWrite) / dataRules=\(supportsDataRules) / battery=\(supportsBattery) / status=\(supportStatus)"
    }
}

public struct SupportedDeviceModel: Sendable {
    public let modelKey: String
    public let modelName: String
    public let seriesKey: String
    public let seriesName: String
    public let profile: DeviceModelProfile

    public init(
        modelKey: String,
        modelName: String,
        seriesKey: String,
        seriesName: String,
        profile: DeviceModelProfile
    ) {
        self.modelKey = modelKey
        self.modelName = modelName
        self.seriesKey = seriesKey
        self.seriesName = seriesName
        self.profile = profile
    }
}

extension DeviceCapabilitySummary {
    internal init(cValue summary: nsdk_device_capability_summary_t) {
        self.init(
            modelKey: stringFromCStringBuffer(summary.model_key),
            modelName: stringFromCStringBuffer(summary.model_name),
            supportsScanControl: summary.supports_scan_control != 0,
            supportsDeviceCommands: summary.supports_device_commands != 0,
            supportsSettingsRead: summary.supports_settings_read != 0,
            supportsSettingsWrite: summary.supports_settings_write != 0,
            supportsDataRules: summary.supports_data_rules != 0,
            supportsBattery: summary.supports_battery != 0,
            supportStatus: DeviceSupportStatus(rawValue: summary.support_status) ?? .unknown
        )
    }
}

public enum CapabilityValueKind: Int32, CaseIterable, Sendable {
    case unknown = 0
    case boolean = 1
    case enumeration = 2
    case uint8 = 3
    case uint16 = 4
    case bytesAscii = 5
    case action = 6
    case complex = 7
    case custom = 8
    case object = 9
    case template = 10
}

public enum CapabilityRiskLevel: Int32, CaseIterable, Sendable {
    case normal = 0
    case destructive = 1
    case connectivity = 2
    case dataLoss = 3
}

public enum CapabilityEntryKind: Int32, CaseIterable, Sendable {
    case setting = 1
    case action = 2
}

public enum CapabilityEntrySource: Int32, CaseIterable, Sendable {
    case module = 0
    case master = 1
    case session = 2
}

public enum CapabilityEntryAvailability: Int32, CaseIterable, Sendable {
    case available = 0
    case unavailableInCurrentTransport = 1
    case unsupportedByProfile = 2
    case shadowedByPreferredRoute = 3
}

public enum CapabilityLabelKind: Int32, CaseIterable, Sendable {
    case domain = 1
    case family = 2
    case section = 3
    case group = 4
    case setting = 5
    case action = 6
    case enumValue = 7
}

public enum SettingCodePayloadKind: Int32, CaseIterable, Sendable {
    case unknown = 0
    case textCommand = 1
    case moduleSettingCode = 2
    case dataRuleTextCommand = 3
    case template = 4
    case commandOnly = 5
    case unavailable = 6
}

public enum SettingCodeSymbology: Int32, CaseIterable, Sendable {
    case unknown = 0
    case code128 = 1
    case qrCode = 2
    case dataMatrix = 3
    case pdf417 = 4
}

public struct CapabilityDomain: Sendable {
    public let key: String
    public let displayName: String
    public let localizationKey: String
    public let sortOrder: UInt32
    public let visibleByDefault: Bool
}

public struct CapabilityOption: Sendable {
    public let value: String
}

public struct CapabilityLabel: Sendable {
    public let kind: CapabilityLabelKind
    public let key: String
    public let ownerKey: String
    public let displayName: String
    public let localizationKey: String
    public let rank: UInt32
}

public struct SdkLocalizationEntry: Sendable {
    public let key: String
    public let locale: String
    public let text: String
}

public struct CapabilityEntry: Sendable {
    public let entryKey: String
    public let kind: CapabilityEntryKind
    public let domainKey: String
    public let groupKey: String
    public let familyKey: String
    public let sectionKey: String
    public let semanticKey: String
    public let defaultValue: String
    public let notes: String
    public let source: CapabilityEntrySource
    public let transportScopes: UInt32
    public let availability: CapabilityEntryAvailability
    public let routePriority: Int32
    public let visibleByDefault: Bool
    public let supportsRead: Bool
    public let supportsWrite: Bool
    public let supportsExecute: Bool
    public let requiresValue: Bool
    public let valueKind: CapabilityValueKind
    public let riskLevel: CapabilityRiskLevel
    public let valueHint: String
    public let options: [CapabilityOption]
}

public struct SettingCodeEntry: Sendable {
    public let codeKey: String
    public let entryKey: String
    public let capabilityKind: CapabilityEntryKind
    public let source: CapabilityEntrySource
    public let semanticKey: String
    public let domainKey: String
    public let valueKind: CapabilityValueKind
    public let riskLevel: CapabilityRiskLevel
    public let requiresValue: Bool
    public let supportsStaticCode: Bool
    public let supportsTemplateCode: Bool
    public let payloadKind: SettingCodePayloadKind
    public let symbology: SettingCodeSymbology
    public let value: String
    public let valueHint: String
    public let payloadText: String
    public let payloadFullSize: UInt32
}

public struct SettingCodeResult: Sendable {
    public let payloadKind: SettingCodePayloadKind
    public let symbology: SettingCodeSymbology
    public let textBytes: Data
    public let textFullSize: UInt32

    public var text: String {
        String(data: textBytes, encoding: .utf8) ?? String(decoding: textBytes, as: UTF8.self)
    }

    public var textBytesComplete: Bool {
        textBytes.count >= Int(textFullSize)
    }

    public var textTruncated: Bool {
        !textBytesComplete
    }
}

extension CapabilityDomain {
    internal init(cValue domain: nsdk_capability_domain_t) {
        let displayName = stringFromCStringBuffer(domain.display_name)
        self.init(
            key: stringFromCStringBuffer(domain.key),
            displayName: displayName,
            localizationKey: stringFromCStringBuffer(domain.localization_key),
            sortOrder: domain.sort_order,
            visibleByDefault: domain.visible_by_default != 0
        )
    }
}

extension CapabilityOption {
    internal init(cValue option: nsdk_capability_option_t) {
        self.init(
            value: stringFromCStringBuffer(option.value)
        )
    }
}

extension CapabilityLabel {
    internal init(cValue label: nsdk_capability_label_t) {
        let displayName = stringFromCStringBuffer(label.display_name)
        self.init(
            kind: CapabilityLabelKind(rawValue: label.kind) ?? .setting,
            key: stringFromCStringBuffer(label.key),
            ownerKey: stringFromCStringBuffer(label.owner_key),
            displayName: displayName,
            localizationKey: stringFromCStringBuffer(label.localization_key),
            rank: label.rank
        )
    }
}

extension SdkLocalizationEntry {
    internal init(cValue entry: nsdk_localization_entry_t) {
        self.init(
            key: stringFromCStringBuffer(entry.key),
            locale: stringFromCStringBuffer(entry.locale),
            text: stringFromCStringBuffer(entry.text)
        )
    }
}

extension CapabilityEntry {
    internal init(cValue entry: nsdk_capability_entry_t, options: [CapabilityOption] = []) {
        self.init(
            entryKey: stringFromCStringBuffer(entry.entry_key),
            kind: CapabilityEntryKind(rawValue: entry.kind) ?? .setting,
            domainKey: stringFromCStringBuffer(entry.domain_key),
            groupKey: stringFromCStringBuffer(entry.group_key),
            familyKey: stringFromCStringBuffer(entry.family_key),
            sectionKey: stringFromCStringBuffer(entry.section_key),
            semanticKey: stringFromCStringBuffer(entry.semantic_key),
            defaultValue: stringFromCStringBuffer(entry.default_value),
            notes: stringFromCStringBuffer(entry.notes),
            source: CapabilityEntrySource(rawValue: entry.source) ?? .module,
            transportScopes: entry.transport_scopes,
            availability: CapabilityEntryAvailability(rawValue: entry.availability) ?? .available,
            routePriority: entry.route_priority,
            visibleByDefault: entry.visible_by_default != 0,
            supportsRead: entry.supports_read != 0,
            supportsWrite: entry.supports_write != 0,
            supportsExecute: entry.supports_execute != 0,
            requiresValue: entry.requires_value != 0,
            valueKind: CapabilityValueKind(rawValue: entry.value_kind) ?? .unknown,
            riskLevel: CapabilityRiskLevel(rawValue: entry.risk_level) ?? .normal,
            valueHint: stringFromCStringBuffer(entry.value_hint),
            options: options
        )
    }

}

extension SettingCodeEntry {
    internal init(cValue entry: nsdk_setting_code_entry_t) {
        self.init(
            codeKey: stringFromCStringBuffer(entry.code_key),
            entryKey: stringFromCStringBuffer(entry.entry_key),
            capabilityKind: CapabilityEntryKind(rawValue: entry.capability_kind) ?? .setting,
            source: CapabilityEntrySource(rawValue: entry.source) ?? .module,
            semanticKey: stringFromCStringBuffer(entry.semantic_key),
            domainKey: stringFromCStringBuffer(entry.domain_key),
            valueKind: CapabilityValueKind(rawValue: entry.value_kind) ?? .unknown,
            riskLevel: CapabilityRiskLevel(rawValue: entry.risk_level) ?? .normal,
            requiresValue: entry.requires_value != 0,
            supportsStaticCode: entry.supports_static_code != 0,
            supportsTemplateCode: entry.supports_template_code != 0,
            payloadKind: SettingCodePayloadKind(rawValue: entry.payload_kind) ?? .unknown,
            symbology: SettingCodeSymbology(rawValue: entry.symbology) ?? .unknown,
            value: stringFromCStringBuffer(entry.value),
            valueHint: stringFromCStringBuffer(entry.value_hint),
            payloadText: stringFromCStringBuffer(entry.payload_text),
            payloadFullSize: entry.payload_full_size
        )
    }
}

extension SettingCodeResult {
    internal init(cValue result: nsdk_setting_code_result_t) {
        let textSize = Int(result.text_size)
        let bytes = withUnsafeBytes(of: result.text_bytes) { rawBuffer in
            Data(rawBuffer.prefix(min(textSize, rawBuffer.count)))
        }
        self.init(
            payloadKind: SettingCodePayloadKind(rawValue: result.payload_kind) ?? .unknown,
            symbology: SettingCodeSymbology(rawValue: result.symbology) ?? .unknown,
            textBytes: bytes,
            textFullSize: result.text_full_size
        )
    }
}

public struct CapabilityValue: Sendable {
    public let kind: CapabilityValueKind
    public let bytes: Data
    public let booleanValue: Bool?
    public let textValue: String?

    public init(
        kind: CapabilityValueKind,
        bytes: Data,
        booleanValue: Bool? = nil,
        textValue: String? = nil
    ) {
        self.kind = kind
        self.bytes = bytes
        self.booleanValue = booleanValue
        self.textValue = textValue
    }

    public static func boolean(_ value: Bool) -> CapabilityValue {
        CapabilityValue(kind: .boolean, bytes: Data([value ? 0x01 : 0x00]), booleanValue: value)
    }

    public static func bytes(_ kind: CapabilityValueKind, _ bytes: Data) -> CapabilityValue {
        CapabilityValue(kind: kind, bytes: bytes)
    }

    public static func asciiText(_ value: String) -> CapabilityValue {
        CapabilityValue(kind: .bytesAscii, bytes: Data(value.utf8), textValue: value)
    }
}

public struct SessionOperationSupport: Sendable {
    public let supportsRefreshInfo: Bool
    public let supportsInitializeSession: Bool
    public let supportsGetBatteryInfo: Bool
    public let supportsApplyDataRule: Bool
    public let supportsTriggerScan: Bool
    public let supportsSetAckBeepEnabled: Bool
    public let supportsSetVibrationEnabled: Bool

    public init(
        supportsRefreshInfo: Bool,
        supportsInitializeSession: Bool,
        supportsGetBatteryInfo: Bool,
        supportsApplyDataRule: Bool,
        supportsTriggerScan: Bool,
        supportsSetAckBeepEnabled: Bool,
        supportsSetVibrationEnabled: Bool
    ) {
        self.supportsRefreshInfo = supportsRefreshInfo
        self.supportsInitializeSession = supportsInitializeSession
        self.supportsGetBatteryInfo = supportsGetBatteryInfo
        self.supportsApplyDataRule = supportsApplyDataRule
        self.supportsTriggerScan = supportsTriggerScan
        self.supportsSetAckBeepEnabled = supportsSetAckBeepEnabled
        self.supportsSetVibrationEnabled = supportsSetVibrationEnabled
    }

    public var displaySummary: String {
        "refreshInfo=\(supportsRefreshInfo) / initializeSession=\(supportsInitializeSession) / getBatteryInfo=\(supportsGetBatteryInfo) / applyDataRule=\(supportsApplyDataRule) / triggerScan=\(supportsTriggerScan) / setAckBeepEnabled=\(supportsSetAckBeepEnabled) / setVibrationEnabled=\(supportsSetVibrationEnabled)"
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

public struct StorageUsage: Sendable {
    public let barcodeCount: Int
    public let used: Int
    public let capacity: Int
    public let remaining: Int
    public let rawText: String
}

public struct ScanEvent: Sendable {
    public let timestampMs: UInt64
    public let barcodeType: Int32
    public let text: String
    public let textBytes: Data
    public let rawBytes: Data
}

public enum TransportIssue: Int32, CaseIterable, Sendable {
    case unknown = 0
    case platformError = 1
    case connectionTimeout = 2
    case bleGattFailure = 3
    case bleServiceDiscoveryStartFailed = 4
    case bleServiceDiscoveryFailed = 5
    case bleNotifyServiceMissing = 6
    case bleNotifyCharacteristicMissing = 7
    case bleNotificationEnableFailed = 8
    case bleNotifyDescriptorMissing = 9
    case bleNotifyDescriptorWriteFailed = 10

    public var localizedLabel: TransportIssueLabel {
        switch self {
        case .bleServiceDiscoveryStartFailed:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.service_discovery_did_not_start", fallbackDisplayName: "Service discovery did not start")
        case .bleServiceDiscoveryFailed:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.service_discovery_failed", fallbackDisplayName: "Service discovery failed")
        case .bleNotifyServiceMissing:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.notify_service_missing", fallbackDisplayName: "Notify service missing")
        case .bleNotifyCharacteristicMissing:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.notify_characteristic_missing", fallbackDisplayName: "Notify characteristic missing")
        case .bleNotificationEnableFailed:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.enabling_notifications_failed", fallbackDisplayName: "Enabling notifications failed")
        case .bleNotifyDescriptorMissing:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.notify_descriptor_missing", fallbackDisplayName: "Notify descriptor missing")
        case .bleNotifyDescriptorWriteFailed:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.notify_descriptor_write_failed", fallbackDisplayName: "Notify descriptor write failed")
        case .connectionTimeout:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.connection_timeout", fallbackDisplayName: "Connection timeout")
        case .bleGattFailure:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.platform_gatt_failure", fallbackDisplayName: "Platform GATT failure")
        case .platformError:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.platform_connection_status_error", fallbackDisplayName: "Platform connection status error")
        case .unknown:
            return TransportIssueLabel(localizationKey: "nsdk.transport_failure_code.unknown_transport_error", fallbackDisplayName: "Unknown transport error")
        }
    }

    public var localizedStatusLabel: TransportFailureStatusLabel {
        switch self {
        case .bleServiceDiscoveryStartFailed,
             .bleServiceDiscoveryFailed,
             .bleNotifyServiceMissing,
             .bleNotifyCharacteristicMissing,
             .bleNotificationEnableFailed,
             .bleNotifyDescriptorMissing,
             .bleNotifyDescriptorWriteFailed:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_setup_failed", fallbackDisplayName: "Connection setup failed")
        case .connectionTimeout:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_timed_out", fallbackDisplayName: "Connection timed out")
        default:
            return TransportFailureStatusLabel(localizationKey: "nsdk.transport_failure_status.connection_failed", fallbackDisplayName: "Connection failed")
        }
    }
}

public struct TransportIssueLabel: Equatable, Sendable {
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

public enum DiscoveryFailureCode: Int32, CaseIterable, Sendable {
    case bleAdapterDisabled = 0
    case bleScannerUnavailable = 1
    case bleFilteredScanFailed = 2
    case bleFilteredScanFallbackFailed = 3
    case bleUnfilteredScanFailed = 4
    case blePermissionDenied = 5

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
        case .blePermissionDenied:
            return DiscoveryFailureCodeLabel(localizationKey: "nsdk.discovery_failure_code.permission_denied", fallbackDisplayName: "Bluetooth permission denied")
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

public enum BleScanIssue: Int32, CaseIterable, Sendable {
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
    public let issue: TransportIssue
    public let message: String
    public let platformErrorCode: Int32?
}

public struct SessionInitializationStageEvent: Sendable {
    public let sessionHandle: UInt64
    public let deviceId: String
    public let selectedModelKey: String
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
        if code == .blePermissionDenied {
            return DiscoveryFailureStatusLabel(localizationKey: "nsdk.discovery_failure_status.permission_denied", fallbackDisplayName: "Bluetooth permission denied")
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
        self = DiscoveryFailureCode(rawValue: cValue) ?? .bleScannerUnavailable
    }
}

extension BleScanIssue {
    internal init(cValue: nsdk_ble_scan_issue_t) {
        self = BleScanIssue(rawValue: cValue) ?? .unknown
    }
}

extension DiscoveryFailure {
    internal init(cValue: nsdk_discovery_failure_t) {
        transportType = TransportType(rawValue: cValue.transport) ?? .bleGatt
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

public enum CommandTraceKind: Int32, CaseIterable, Sendable {
    case unknown = 0
    case master = 2
    case text = 3
    case dataRule = 4
    case capabilityRead = 5
    case capabilityWrite = 6
    case scanControl = 7
    case capabilityAction = 8
}

public struct CommandTrace: Sendable {
    public let sessionHandle: UInt64
    public let timestampMs: UInt64
    public let durationMs: UInt64
    public let transportType: TransportType
    public let resolvedModelKey: String
    public let kind: CommandTraceKind
    public let errorCode: Int32
    public let acknowledged: Bool
    public let requestAvailable: Bool
    public let responseAvailable: Bool
    public let operation: String
    public let entryKey: String
    public let semanticKey: String
    public let domainKey: String
    public let routeSource: CapabilityEntrySource
    public let requestText: String
    public let requestHex: String
    public let responseText: String
    public let responseHex: String

    public init(
        sessionHandle: UInt64,
        timestampMs: UInt64,
        durationMs: UInt64,
        transportType: TransportType,
        resolvedModelKey: String,
        kind: CommandTraceKind,
        errorCode: Int32,
        acknowledged: Bool,
        requestAvailable: Bool,
        responseAvailable: Bool,
        operation: String,
        entryKey: String = "",
        semanticKey: String = "",
        domainKey: String = "",
        routeSource: CapabilityEntrySource = .module,
        requestText: String,
        requestHex: String,
        responseText: String,
        responseHex: String
    ) {
        self.sessionHandle = sessionHandle
        self.timestampMs = timestampMs
        self.durationMs = durationMs
        self.transportType = transportType
        self.resolvedModelKey = resolvedModelKey
        self.kind = kind
        self.errorCode = errorCode
        self.acknowledged = acknowledged
        self.requestAvailable = requestAvailable
        self.responseAvailable = responseAvailable
        self.operation = operation
        self.entryKey = entryKey
        self.semanticKey = semanticKey
        self.domainKey = domainKey
        self.routeSource = routeSource
        self.requestText = requestText
        self.requestHex = requestHex
        self.responseText = responseText
        self.responseHex = responseHex
    }
}

extension CommandTrace {
    internal init(cValue trace: nsdk_command_trace_t) {
        self.init(
            sessionHandle: trace.session,
            timestampMs: trace.timestamp_ms,
            durationMs: trace.duration_ms,
            transportType: TransportType(rawValue: trace.transport) ?? .bleGatt,
            resolvedModelKey: stringFromCStringBuffer(trace.resolved_model_key),
            kind: CommandTraceKind(rawValue: trace.kind) ?? .unknown,
            errorCode: trace.error_code,
            acknowledged: trace.acknowledged != 0,
            requestAvailable: trace.request_available != 0,
            responseAvailable: trace.response_available != 0,
            operation: stringFromCStringBuffer(trace.operation),
            entryKey: stringFromCStringBuffer(trace.entry_key),
            semanticKey: stringFromCStringBuffer(trace.semantic_key),
            domainKey: stringFromCStringBuffer(trace.domain_key),
            routeSource: CapabilityEntrySource(rawValue: trace.route_source) ?? .module,
            requestText: stringFromCStringBuffer(trace.request_text),
            requestHex: stringFromCStringBuffer(trace.request_hex),
            responseText: stringFromCStringBuffer(trace.response_text),
            responseHex: stringFromCStringBuffer(trace.response_hex)
        )
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

    public init(
        textBytes: Data,
        textFullSize: Int? = nil,
        textBytesComplete: Bool? = nil,
        rawBytes: Data,
        acknowledged: Bool,
        recordCount: Int,
        recordBytes: [Data],
        recordsComplete: Bool
    ) {
        let resolvedTextFullSize = textFullSize ?? textBytes.count
        self.textBytes = textBytes
        self.textFullSize = resolvedTextFullSize
        self.textBytesComplete = textBytesComplete ?? (textBytes.count >= resolvedTextFullSize)
        self.rawBytes = rawBytes
        self.acknowledged = acknowledged
        self.recordCount = recordCount
        self.recordBytes = recordBytes
        self.recordsComplete = recordsComplete
    }

    public var textTruncated: Bool {
        !textBytesComplete
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
