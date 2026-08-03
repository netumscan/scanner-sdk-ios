import CryptoKit
import Foundation

public struct LogExportRequest: Sendable {
    public let includeScanPayload: Bool
    public let redactScanPayload: Bool
    public let from: Date?
    public let to: Date?
    public let maxEvents: Int?
    public let directory: URL?

    public init(
        includeScanPayload: Bool = false,
        redactScanPayload: Bool = true,
        from: Date? = nil,
        to: Date? = nil,
        maxEvents: Int? = nil,
        directory: URL? = nil
    ) {
        self.includeScanPayload = includeScanPayload
        self.redactScanPayload = redactScanPayload
        self.from = from
        self.to = to
        self.maxEvents = maxEvents
        self.directory = directory
    }
}

public struct LogPackage: Sendable {
    public let path: String
    public let generatedAt: Date
    public let redacted: Bool
    public let eventCount: Int

    public init(path: String, generatedAt: Date, redacted: Bool, eventCount: Int) {
        self.path = path
        self.generatedAt = generatedAt
        self.redacted = redacted
        self.eventCount = eventCount
    }
}

internal struct DiagnosticEvent {
    let type: String
    let happenedAt: Date
    let level: String
    let message: String?
    let fields: [String: Any?]
}

internal final class DiagnosticsRecorder: @unchecked Sendable {
    private let maxEvents: Int
    private let lock = NSLock()
    private var events: [DiagnosticEvent] = []
    private var knownDeviceIds: Set<String> = []

    init(maxEvents: Int = 600) {
        self.maxEvents = maxEvents
    }

    func observeDeviceId(_ deviceId: String?) {
        let normalized = (deviceId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        lock.lock()
        knownDeviceIds.insert(normalized)
        lock.unlock()
    }

    func record(
        type: String,
        level: String = "info",
        message: String? = nil,
        fields: [String: Any?] = [:],
        happenedAt: Date = Date()
    ) {
        if let deviceId = fields["deviceId"] as? String {
            observeDeviceId(deviceId)
        }
        lock.lock()
        events.append(
            DiagnosticEvent(
                type: type,
                happenedAt: happenedAt,
                level: level,
                message: message,
                fields: fields
            )
        )
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        lock.unlock()
    }

    func export(
        request: LogExportRequest,
        context: DiagnosticsExportContext
    ) throws -> LogPackage {
        let generatedAt = Date()
        let redacted = request.redactScanPayload || !request.includeScanPayload
        let snapshot = filteredSnapshot(request: request)
        let exportDirectory = try resolveExportDirectory(request.directory)
        let fileURL = exportDirectory.appendingPathComponent(
            "scanner_bridge_ios_logs_\(Int(generatedAt.timeIntervalSince1970 * 1000)).zip"
        )
        let redactor = DiagnosticsRedactor(knownDeviceIds: knownDeviceIdsSnapshot(extra: context.activeDeviceId))
        let files: [(String, Data)] = [
            (
                "manifest.json",
                jsonData(
                    manifest(
                        context: context,
                        generatedAt: generatedAt,
                        redacted: redacted,
                        eventCount: snapshot.count
                    )
                )
            ),
            ("events.jsonl", jsonLinesData(snapshot.map { eventJson($0, redactor: redactor) })),
            (
                "summary.txt",
                Data(
                    summaryText(
                        context: context,
                        generatedAt: generatedAt,
                        redacted: redacted,
                        events: snapshot,
                        redactor: redactor
                    ).utf8
                )
            ),
        ] + (request.includeScanPayload && !request.redactScanPayload
            ? [("scan_payload_unredacted.jsonl", jsonLinesData(scanPayloadJson(snapshot)))]
            : [])
        try ZipStoreWriter.write(files: files, to: fileURL)
        record(
            type: "export",
            message: "exportNativeLogs",
            fields: [
                "path": fileURL.path,
                "redacted": redacted,
                "eventCount": snapshot.count,
            ],
            happenedAt: generatedAt
        )
        return LogPackage(
            path: fileURL.path,
            generatedAt: generatedAt,
            redacted: redacted,
            eventCount: snapshot.count
        )
    }

    private func filteredSnapshot(request: LogExportRequest) -> [DiagnosticEvent] {
        lock.lock()
        var snapshot = events
        lock.unlock()
        if let from = request.from {
            snapshot = snapshot.filter { $0.happenedAt >= from }
        }
        if let to = request.to {
            snapshot = snapshot.filter { $0.happenedAt <= to }
        }
        if let maxEvents = request.maxEvents, maxEvents > 0, snapshot.count > maxEvents {
            snapshot = Array(snapshot.suffix(maxEvents))
        }
        return snapshot
    }

    private func knownDeviceIdsSnapshot(extra: String?) -> Set<String> {
        lock.lock()
        var snapshot = knownDeviceIds
        lock.unlock()
        if let extra, !extra.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            snapshot.insert(extra)
        }
        return snapshot
    }

    private func resolveExportDirectory(_ requestedDirectory: URL?) throws -> URL {
        let directory = requestedDirectory ??
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("scanner_bridge_logs", isDirectory: true) ??
            FileManager.default.temporaryDirectory.appendingPathComponent("scanner_bridge_logs", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func manifest(
        context: DiagnosticsExportContext,
        generatedAt: Date,
        redacted: Bool,
        eventCount: Int
    ) -> [String: Any?] {
        [
            "platform": context.platform,
            "bridgeVersion": context.bridgeVersion,
            "sdkVersion": context.sdkVersion,
            "exportedAtMs": Int(generatedAt.timeIntervalSince1970 * 1000),
            "exportedAt": isoTimestamp(generatedAt),
            "redacted": redacted,
            "eventCount": eventCount,
            "activeSession": [
                "deviceIdHash": context.activeDeviceId.map(deviceIdHash),
                "selectedModelId": context.activeSelectedModelId,
                "sessionState": context.activeSessionState,
            ],
            "packageKind": "ios_bridge_diagnostics",
            "nativeSdkLogApi": "scanner-sdk-swift-wrapper",
            "redaction": [
                "deviceId_hash",
                "scan_payload_summary",
                "debug_message_allowlist_cleanup",
                "mac_address_mask",
                "hex_payload_mask",
            ],
        ]
    }

    private func eventJson(_ event: DiagnosticEvent, redactor: DiagnosticsRedactor) -> [String: Any?] {
        [
            "type": event.type,
            "happenedAtMs": Int(event.happenedAt.timeIntervalSince1970 * 1000),
            "level": event.level,
            "message": event.message.map(redactor.cleanMessage),
            "fields": redactor.cleanFields(event.fields),
        ]
    }

    private func summaryText(
        context: DiagnosticsExportContext,
        generatedAt: Date,
        redacted: Bool,
        events: [DiagnosticEvent],
        redactor: DiagnosticsRedactor
    ) -> String {
        let counts = Dictionary(grouping: events, by: \.type).mapValues(\.count).sorted { $0.key < $1.key }
        let failures = events.filter { $0.type == "failure" }.suffix(5)
        var lines = [
            "NETUM scanner_bridge iOS diagnostics",
            "exportedAt=\(isoTimestamp(generatedAt))",
            "bridgeVersion=\(context.bridgeVersion)",
            "sdkVersion=\(context.sdkVersion)",
            "redacted=\(redacted)",
            "activeDeviceIdHash=\(context.activeDeviceId.map(deviceIdHash) ?? "-")",
            "activeSelectedModelId=\(context.activeSelectedModelId ?? "-")",
            "activeSessionState=\(context.activeSessionState ?? "-")",
            "eventCount=\(events.count)",
            "eventTypes=\(counts.map { "\($0.key):\($0.value)" }.joined(separator: ","))",
        ]
        if !failures.isEmpty {
            lines.append("")
            lines.append("recentFailures:")
            for failure in failures {
                lines.append("- \(isoTimestamp(failure.happenedAt)) \(failure.message ?? "-") \(jsonString(redactor.cleanFields(failure.fields)))")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func scanPayloadJson(_ events: [DiagnosticEvent]) -> [[String: Any?]] {
        events.filter { $0.type == "scanSummary" }.map { event in
            let deviceId = event.fields["deviceId"] as? String
            let rawBytes = event.fields["rawBytes"] ?? nil
            let text = event.fields["text"] ?? nil
            let symbology = event.fields["symbology"] ?? nil
            return [
                "happenedAtMs": Int(event.happenedAt.timeIntervalSince1970 * 1000),
                "deviceIdHash": deviceId.map(deviceIdHash),
                "rawBytes": rawBytes,
                "text": text,
                "textHash": (event.fields["text"] as? String).map(sha256Short),
                "symbology": symbology,
                "warning": "unredacted_scan_payload_requested",
            ]
        }
    }
}

internal struct DiagnosticsExportContext {
    let platform: String
    let bridgeVersion: String
    let sdkVersion: String
    let activeDeviceId: String?
    let activeSelectedModelId: String?
    let activeSessionState: String?
}

private struct DiagnosticsRedactor {
    let knownDeviceIds: Set<String>

    func cleanFields(_ fields: [String: Any?]) -> [String: Any?] {
        fields.reduce(into: [:]) { result, entry in
            let key = entry.key
            let value = entry.value
            if key.caseInsensitiveCompare("deviceId") == .orderedSame {
                result[key] = (value as? String).map(deviceIdHash)
            } else if key.caseInsensitiveCompare("rawBytes") == .orderedSame {
                result[key] = (value as? [UInt8]).map { "redacted_length=\($0.count)" } ??
                    (value as? [Int]).map { "redacted_length=\($0.count)" }
            } else if key.caseInsensitiveCompare("text") == .orderedSame {
                result[key] = (value as? String).map { "redacted_sha256=\(sha256Short($0))" }
            } else if let string = value as? String {
                result[key] = cleanMessage(string)
            } else if let dictionary = value as? [String: Any?] {
                result[key] = cleanFields(dictionary)
            } else {
                result[key] = value
            }
        }
    }

    func cleanMessage(_ message: String) -> String {
        var cleaned = message
        for deviceId in knownDeviceIds where !deviceId.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: deviceId, with: deviceIdHash(deviceId))
        }
        cleaned = cleaned.replacingOccurrences(
            of: #"(?i)\b[0-9a-f]{2}(:[0-9a-f]{2}){5}\b"#,
            with: "<id>",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"(?i)\bhex=([0-9a-f]{2}[\s:-]*){2,}"#,
            with: "hex=<redacted>",
            options: .regularExpression
        )
        return cleaned
    }
}

private struct ZipStoreWriter {
    static func write(files: [(String, Data)], to url: URL) throws {
        var body = Data()
        var central = Data()
        var offset: UInt32 = 0
        for file in files {
            let nameData = Data(file.0.utf8)
            let crc = crc32(file.1)
            body.appendUInt32LE(0x04034b50)
            body.appendUInt16LE(20)
            body.appendUInt16LE(0)
            body.appendUInt16LE(0)
            body.appendUInt16LE(0)
            body.appendUInt16LE(0)
            body.appendUInt32LE(crc)
            body.appendUInt32LE(UInt32(file.1.count))
            body.appendUInt32LE(UInt32(file.1.count))
            body.appendUInt16LE(UInt16(nameData.count))
            body.appendUInt16LE(0)
            body.append(nameData)
            body.append(file.1)

            central.appendUInt32LE(0x02014b50)
            central.appendUInt16LE(20)
            central.appendUInt16LE(20)
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt32LE(crc)
            central.appendUInt32LE(UInt32(file.1.count))
            central.appendUInt32LE(UInt32(file.1.count))
            central.appendUInt16LE(UInt16(nameData.count))
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt16LE(0)
            central.appendUInt32LE(0)
            central.appendUInt32LE(offset)
            central.append(nameData)
            offset = UInt32(body.count)
        }
        let centralOffset = UInt32(body.count)
        body.append(central)
        body.appendUInt32LE(0x06054b50)
        body.appendUInt16LE(0)
        body.appendUInt16LE(0)
        body.appendUInt16LE(UInt16(files.count))
        body.appendUInt16LE(UInt16(files.count))
        body.appendUInt32LE(UInt32(central.count))
        body.appendUInt32LE(centralOffset)
        body.appendUInt16LE(0)
        try body.write(to: url, options: .atomic)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1
            }
        }
        return crc ^ 0xffffffff
    }
}

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}

private func jsonData(_ value: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: sanitizeJson(value), options: [.sortedKeys])) ?? Data("{}".utf8)
}

private func jsonString(_ value: Any) -> String {
    String(data: jsonData(value), encoding: .utf8) ?? "{}"
}

private func jsonLinesData(_ rows: [[String: Any?]]) -> Data {
    Data(rows.map(jsonString).joined(separator: "\n").appending("\n").utf8)
}

private func sanitizeJson(_ value: Any) -> Any {
    if let dictionary = value as? [String: Any?] {
        return dictionary.reduce(into: [String: Any]()) { result, entry in
            result[entry.key] = sanitizeJson(entry.value as Any)
        }
    }
    if let array = value as? [Any?] {
        return array.map { sanitizeJson($0 as Any) }
    }
    if value is NSNull {
        return NSNull()
    }
    if let optional = value as? OptionalProtocol, optional.isNil {
        return NSNull()
    }
    return value
}

private protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    fileprivate var isNil: Bool {
        self == nil
    }
}

private func deviceIdHash(_ deviceId: String) -> String {
    "sha256:\(sha256Short(deviceId))"
}

internal func sha256Short(_ value: String) -> String {
    let digest = SHA256.hash(data: Data(value.utf8))
    return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
}

private func isoTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
