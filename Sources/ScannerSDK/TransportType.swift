import Foundation
import CNSDK

public enum TransportType: Int32, CaseIterable, Sendable {
    case bleGatt = 0
    case usbHid = 1
    case usbSerial = 2
    case sppClassic = 3

    public var localizedLabel: TransportTypeLabel {
        switch self {
        case .bleGatt:
            return TransportTypeLabel(localizationKey: "nsdk.transport_type.ble_gatt", fallbackDisplayName: "BLE GATT")
        case .usbHid:
            return TransportTypeLabel(localizationKey: "nsdk.transport_type.usb_hid", fallbackDisplayName: "USB HID")
        case .usbSerial:
            return TransportTypeLabel(localizationKey: "nsdk.transport_type.usb_serial", fallbackDisplayName: "USB Serial")
        case .sppClassic:
            return TransportTypeLabel(localizationKey: "nsdk.transport_type.spp_classic", fallbackDisplayName: "SPP Classic")
        }
    }

    internal var cValue: nsdk_transport_type_t {
        nsdk_transport_type_t(rawValue)
    }
}

public struct TransportTypeLabel: Equatable, Sendable {
    public let localizationKey: String
    public let fallbackDisplayName: String

    public init(localizationKey: String, fallbackDisplayName: String) {
        self.localizationKey = localizationKey
        self.fallbackDisplayName = fallbackDisplayName
    }
}
