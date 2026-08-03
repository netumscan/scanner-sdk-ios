import Foundation
import CNSDK

public enum SessionInitializationStage: Int32, Sendable {
    case started = 0
    case readingDeviceInfo = 1
    case readingBattery = 2
    case readingCapabilitySummary = 3
    case readingOperationSupport = 4
    case completed = 5
    case failed = 6
    case unknown = -1

    internal init(cValue: nsdk_session_initialization_stage_t) {
        self = SessionInitializationStage(rawValue: cValue) ?? .unknown
    }
}
