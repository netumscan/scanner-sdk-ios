import Foundation
import CNSDK

public enum SessionState: UInt32, Sendable {
    case idle = 0
    case discovering = 1
    case connecting = 2
    case connected = 3
    case ready = 4
    case busy = 5
    case reconnecting = 6
    case disconnected = 7
    case error = 8

    internal init(cValue: nsdk_session_state_t) {
        self = SessionState(rawValue: cValue.rawValue) ?? .error
    }

    public var localizedLabel: SessionStateLabel {
        switch self {
        case .idle:
            return SessionStateLabel(localizationKey: "nsdk.session_state.idle", fallbackDisplayName: "Idle")
        case .discovering:
            return SessionStateLabel(localizationKey: "nsdk.session_state.discovering", fallbackDisplayName: "Discovering")
        case .connecting:
            return SessionStateLabel(localizationKey: "nsdk.session_state.connecting", fallbackDisplayName: "Connecting")
        case .connected:
            return SessionStateLabel(localizationKey: "nsdk.session_state.connected_preparing", fallbackDisplayName: "Connected, preparing")
        case .ready:
            return SessionStateLabel(localizationKey: "nsdk.session_state.connected_ready", fallbackDisplayName: "Connected, ready")
        case .busy:
            return SessionStateLabel(localizationKey: "nsdk.session_state.busy", fallbackDisplayName: "Busy")
        case .reconnecting:
            return SessionStateLabel(localizationKey: "nsdk.session_state.reconnecting", fallbackDisplayName: "Reconnecting")
        case .disconnected:
            return SessionStateLabel(localizationKey: "nsdk.session_state.disconnected", fallbackDisplayName: "Disconnected")
        case .error:
            return SessionStateLabel(localizationKey: "nsdk.session_state.connection_error", fallbackDisplayName: "Connection error")
        }
    }
}

public struct SessionStateLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
