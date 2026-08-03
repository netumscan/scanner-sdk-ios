import Foundation

public enum DeviceCharset: String, CaseIterable, Sendable {
    case auto = "Auto"
    case gbk = "GBK"
    case utf8Word = "UTF8 (Word)"
    case iso8859 = "ISO/IEC 8859"
    case normal = "Normal"
    case utf8Txt = "UTF8 (Txt)"

    public init?(protocolValue: String) {
        let normalized = protocolValue.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(rawValue: normalized)
    }

    public var displayName: String {
        switch self {
        case .utf8Word:
            return "UTF-8 (Word)"
        case .utf8Txt:
            return "UTF-8 (Text)"
        default:
            return rawValue
        }
    }

    public var localizedLabel: DeviceCharsetLabel {
        switch self {
        case .auto:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.auto", fallbackDisplayName: "Auto")
        case .gbk:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.gbk", fallbackDisplayName: "GBK")
        case .utf8Word:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.utf8_word", fallbackDisplayName: "UTF-8 (Word)")
        case .iso8859:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.iso_iec_8859", fallbackDisplayName: "ISO/IEC 8859")
        case .normal:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.normal", fallbackDisplayName: "Normal")
        case .utf8Txt:
            return DeviceCharsetLabel(localizationKey: "nsdk.device_charset.utf8_txt", fallbackDisplayName: "UTF-8 (Text)")
        }
    }
}

public struct DeviceCharsetLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
