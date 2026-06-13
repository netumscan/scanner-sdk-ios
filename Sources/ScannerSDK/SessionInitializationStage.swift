import Foundation
import CNSDK

public enum SessionInitializationStage: UInt32, Sendable {
    case sessionInitStarted = 0
    case readingDeviceInfo = 1
    case readingBattery = 2
    case readingCapabilitySummary = 3
    case readingOperationSupport = 4
    case sessionInitCompleted = 5
    case sessionInitFailed = 6
    case unknown = 0xFFFF_FFFF

    internal init(cValue: nsdk_session_init_stage_t) {
        self = SessionInitializationStage(rawValue: cValue.rawValue) ?? .unknown
    }
}
