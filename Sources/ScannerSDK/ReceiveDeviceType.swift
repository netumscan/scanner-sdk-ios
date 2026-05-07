import Foundation

public enum ReceiveDeviceType: CaseIterable, Sendable {
    case windows
    case macOsIos
    case android

    public init?(protocolValue: String) {
        switch protocolValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "windows", "windows system device":
            self = .windows
        case "macos/ios", "iphone/ipad/mac device", "mac/ios":
            self = .macOsIos
        case "android", "android system device", "androd":
            self = .android
        default:
            return nil
        }
    }

    public var displayName: String {
        switch self {
        case .windows: return "Windows"
        case .macOsIos: return "Mac/iOS"
        case .android: return "Android"
        }
    }

    public var localizedLabel: ReceiveDeviceTypeLabel {
        switch self {
        case .windows:
            return ReceiveDeviceTypeLabel(localizationKey: "nsdk.receive_device_type.windows", fallbackDisplayName: "Windows")
        case .macOsIos:
            return ReceiveDeviceTypeLabel(localizationKey: "nsdk.receive_device_type.mac_ios", fallbackDisplayName: "Mac/iOS")
        case .android:
            return ReceiveDeviceTypeLabel(localizationKey: "nsdk.receive_device_type.android", fallbackDisplayName: "Android")
        }
    }
}

public struct ReceiveDeviceTypeLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
