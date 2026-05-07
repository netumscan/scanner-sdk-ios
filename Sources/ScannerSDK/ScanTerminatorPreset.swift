import Foundation

public struct ScanTerminatorPreset: Identifiable, Hashable, Sendable {
    public let label: String
    public let summary: String
    public let bytes: Data

    public var id: String { summary }

    public init(label: String, summary: String, bytes: Data) {
        self.label = label
        self.summary = summary
        self.bytes = bytes
    }

    public static let cr = ScanTerminatorPreset(label: "CR", summary: "0D", bytes: Data([0x0D]))
    public static let lf = ScanTerminatorPreset(label: "LF", summary: "0A", bytes: Data([0x0A]))
    public static let crlf = ScanTerminatorPreset(label: "CRLF", summary: "0D 0A", bytes: Data([0x0D, 0x0A]))
    public static let tab = ScanTerminatorPreset(label: "TAB", summary: "09", bytes: Data([0x09]))

    public static let defaults: [ScanTerminatorPreset] = [.cr, .lf, .crlf, .tab]
}
