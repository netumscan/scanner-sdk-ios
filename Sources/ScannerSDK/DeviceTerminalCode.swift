import Foundation

public enum DeviceTerminalCode: String, CaseIterable, Sendable {
    case none = "None"
    case cr = "CR"
    case tab = "TAB"
    case crlf = "CRLF"
    case lf = "LF"

    public init?(protocolValue: String) {
        let normalized = protocolValue.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(rawValue: normalized)
    }

    public var displayName: String { rawValue }

    public var localizedLabel: DeviceTerminalCodeLabel {
        switch self {
        case .none:
            return DeviceTerminalCodeLabel(localizationKey: "nsdk.device_terminal_code.none", fallbackDisplayName: "None")
        case .cr:
            return DeviceTerminalCodeLabel(localizationKey: "nsdk.device_terminal_code.cr", fallbackDisplayName: "CR")
        case .tab:
            return DeviceTerminalCodeLabel(localizationKey: "nsdk.device_terminal_code.tab", fallbackDisplayName: "TAB")
        case .crlf:
            return DeviceTerminalCodeLabel(localizationKey: "nsdk.device_terminal_code.crlf", fallbackDisplayName: "CRLF")
        case .lf:
            return DeviceTerminalCodeLabel(localizationKey: "nsdk.device_terminal_code.lf", fallbackDisplayName: "LF")
        }
    }
}

public struct DeviceTerminalCodeLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
