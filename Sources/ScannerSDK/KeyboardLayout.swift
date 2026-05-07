import Foundation

public enum KeyboardLayout: String, CaseIterable, Sendable {
    case en = "EN"
    case fr = "FR"
    case ge = "GE"
    case it = "IT"
    case pt = "PT"
    case es = "ES"
    case tk = "TK"
    case tf = "TF"
    case uk = "UK"
    case cs = "CS"
    case cy = "CY"
    case hu = "HU"
    case fb = "FB"
    case pb = "PB"
    case fc = "FC"
    case hr = "HR"
    case sk = "SK"
    case sq = "SQ"
    case da = "DA"
    case fi = "FI"
    case el = "EL"
    case nl = "NL"
    case no = "NO"
    case pl = "PL"
    case sr = "SR"
    case sl = "SL"
    case sv = "SV"
    case ds = "DS"
    case jp = "JP"
    case th = "TH"
    case ag = "AG"
    case ru = "RU"

    public init?(protocolValue: String) {
        let normalized = protocolValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.init(rawValue: normalized)
    }

    public var displayName: String { rawValue }

    public var localizedLabel: KeyboardLayoutLabel {
        KeyboardLayoutLabel(localizationKey: "nsdk.keyboard_layout.\(rawValue.lowercased())", fallbackDisplayName: rawValue)
    }
}

public struct KeyboardLayoutLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
