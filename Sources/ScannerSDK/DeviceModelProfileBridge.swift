import Foundation
import CNSDK

internal enum DeviceModelProfileBridge {
    static func load(_ modelId: DeviceModelId) -> DeviceModelProfile? {
        guard modelId != .unknown else {
            return nil
        }

        var profile = nsdk_device_model_profile_t()
        let result = nsdk_get_device_model_profile(nsdk_device_model_id_t(rawValue: modelId.rawValue), &profile)
        guard result == 0 else {
            return nil
        }

        return DeviceModelProfile(
            capability: makeCapabilitySummary(profile.capability),
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
            usbHidReportId: profile.usb_hid_report_id < 0 ? nil : Int(profile.usb_hid_report_id),
            usbHidFramingMode: UsbHidFramingMode(rawValue: Int(profile.usb_hid_framing_mode)) ?? .none
        )
    }

    private static func makeCapabilitySummary(_ summary: nsdk_device_capability_summary_t) -> DeviceCapabilitySummary {
        DeviceCapabilitySummary(
            modelId: DeviceModelId(rawValue: summary.model_id.rawValue) ?? .unknown,
            modelName: stringFromCStringBuffer(summary.model_name),
            defaultCommandSet: CommandSetKind(rawValue: summary.default_command_set.rawValue) ?? .unknown,
            formFactor: DeviceFormFactor(rawValue: summary.form_factor.rawValue) ?? .unknown,
            moduleFamily: ModuleFamily(rawValue: summary.module_family.rawValue) ?? .unknown,
            supportsBasicDeviceCommands: summary.supports_basic_device_commands != 0,
            supportsMasterCommands: summary.supports_master_commands != 0,
            supportsNativeModuleCommands: summary.supports_native_module_commands != 0,
            supportsModuleCommandBridge: summary.supports_module_command_bridge != 0,
            supportsModuleCommands: summary.supports_module_commands != 0,
            supportsScannerMaster: summary.supports_scanner_master != 0,
            supportsModulePassthrough: summary.supports_module_passthrough != 0,
            supportStatus: SupportStatus(rawValue: summary.support_status.rawValue) ?? .unknown
        )
    }
}
