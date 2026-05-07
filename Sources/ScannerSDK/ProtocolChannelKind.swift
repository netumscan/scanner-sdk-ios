import Foundation
import CNSDK

public enum ProtocolChannelKind: UInt32, CaseIterable, Sendable {
    case scannerMaster = 0
    case modulePassthrough = 1

    internal var cValue: nsdk_protocol_channel_kind_t {
        nsdk_protocol_channel_kind_t(rawValue: rawValue)
    }

    public var localizedLabel: ProtocolChannelKindLabel {
        switch self {
        case .scannerMaster:
            return ProtocolChannelKindLabel(localizationKey: "nsdk.protocol_channel_kind.scanner_master", fallbackDisplayName: "Scanner master")
        case .modulePassthrough:
            return ProtocolChannelKindLabel(localizationKey: "nsdk.protocol_channel_kind.module_passthrough", fallbackDisplayName: "Module passthrough")
        }
    }
}

public struct ProtocolChannelKindLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
