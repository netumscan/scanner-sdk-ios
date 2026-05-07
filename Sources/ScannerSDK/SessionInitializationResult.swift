import Foundation

public struct SessionInitializationResult: Sendable {
    public let info: ScannerInfo
    public let batteryInfo: BatteryInfo
    public let modelConfigApplied: Bool
}
