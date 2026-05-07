import Foundation

public enum DecoderModule: CaseIterable, Sendable {
    case se4750
    case ntc06h
    case ex25xx
    case nt280h
    case nt212x
    case n4680x

    public init?(protocolValue: String) {
        switch protocolValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .lowercased() {
        case "0", "se4750":
            self = .se4750
        case "1", "ntc06h":
            self = .ntc06h
        case "2", "ex25xx":
            self = .ex25xx
        case "3", "nt280h":
            self = .nt280h
        case "4", "nt212x":
            self = .nt212x
        case "5", "n4680x":
            self = .n4680x
        default:
            return nil
        }
    }

    public var displayName: String {
        switch self {
        case .se4750: return "SE4750"
        case .ntc06h: return "NTC06H"
        case .ex25xx: return "EX25XX"
        case .nt280h: return "NT280H"
        case .nt212x: return "NT212X"
        case .n4680x: return "N4680X"
        }
    }
}
