import Foundation

public struct EventOverflow: Sendable, Equatable {
    public enum Source: String, Sendable {
        case scan
    }

    public let source: Source
    public let droppedCount: UInt64
    public let timestamp: Date

    public init(source: Source, droppedCount: UInt64, timestamp: Date = Date()) {
        self.source = source
        self.droppedCount = droppedCount
        self.timestamp = timestamp
    }
}
