import Foundation
import CNSDK

internal enum DeviceModelProfileBridge {
    static func load(_ modelKey: String) -> DeviceModelProfile? {
        guard !modelKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        var profile = makeNsdkDeviceModelProfile()
        let result = modelKey.withCString { nsdk_device_model_get_profile($0, &profile) }
        guard result == 0 else {
            return nil
        }

        return decode(profile)
    }

    static func loadSupportedModels(transport: TransportType) throws -> [SupportedDeviceModel] {
        var count: UInt32 = 0
        try nsdkCheck(
            nsdk_device_model_count(transport.cValue, &count),
            operation: "getSupportedDeviceModels"
        )
        guard count > 0 else {
            return []
        }

        var models: [SupportedDeviceModel] = []
        models.reserveCapacity(Int(count))
        for index in 0..<count {
            var model = makeNsdkSupportedDeviceModel()
            try nsdkCheck(
                nsdk_device_model_get_at(transport.cValue, index, &model),
                operation: "getSupportedDeviceModels"
            )
            models.append(
                SupportedDeviceModel(
                    modelKey: stringFromCStringBuffer(model.model_key),
                    modelName: stringFromCStringBuffer(model.model_name),
                    seriesKey: stringFromCStringBuffer(model.series_key),
                    seriesName: stringFromCStringBuffer(model.series_name),
                    profile: decode(model.profile)
                )
            )
        }
        return models
    }

    private static func decode(_ profile: nsdk_device_model_profile_t) -> DeviceModelProfile {
        return DeviceModelProfile(
            capability: DeviceCapabilitySummary(cValue: profile.capability),
            bleServiceUuids: decodeCStringTable(
                profile.ble_service_uuids,
                entrySize: 40,
                count: profile.ble_service_uuid_count
            ),
            bleNameHints: decodeCStringTable(
                profile.ble_name_hints,
                entrySize: 64,
                count: profile.ble_name_hint_count
            ),
            usbVendorId: profile.usb_vendor_id == 0 ? nil : Int(profile.usb_vendor_id),
            usbProductIds: decodeUInt16Table(
                profile.usb_product_ids,
                count: profile.usb_product_id_count
            ),
            usbInterfaceNumber: profile.usb_interface_number < 0 ? nil : Int(profile.usb_interface_number),
            usbHidReportId: profile.usb_hid_report_id < 0 ? nil : Int(profile.usb_hid_report_id)
        )
    }
}
