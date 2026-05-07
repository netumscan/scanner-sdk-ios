import Foundation
import CoreFoundation

public enum ScanTextCharset: CaseIterable, Hashable, Sendable {
    case utf8
    case usASCII
    case iso88591
    case gbk

    public var encoding: String.Encoding {
        switch self {
        case .utf8: return .utf8
        case .usASCII: return .ascii
        case .iso88591: return .isoLatin1
        case .gbk:
            let cfEncoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        }
    }

    public var displayName: String {
        switch self {
        case .utf8: return "UTF_8"
        case .usASCII: return "US_ASCII"
        case .iso88591: return "ISO_8859_1"
        case .gbk: return "GBK"
        }
    }
}
