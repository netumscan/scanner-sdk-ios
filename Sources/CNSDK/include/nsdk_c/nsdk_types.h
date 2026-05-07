#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t nsdk_error_t;
typedef int32_t nsdk_master_command_id_t;
typedef uint64_t nsdk_session_handle_t;

typedef enum nsdk_command_code_t {
    NSDK_COMMAND_CODE_GET_INFO = 0x0001,
    NSDK_COMMAND_CODE_GET_BATTERY_INFO = 0x0002,
    NSDK_COMMAND_CODE_TRIGGER_SCAN = 0x0004,
    NSDK_COMMAND_CODE_STOP_SCAN = 0x0005,
    NSDK_COMMAND_CODE_BEEP = 0x0006,
    NSDK_COMMAND_CODE_DISABLE_ACK_BEEP = 0x0007,
    NSDK_COMMAND_CODE_VIBRATE_ON = 0x0008,
    NSDK_COMMAND_CODE_VIBRATE_OFF = 0x0009,
    NSDK_COMMAND_CODE_SCAN_EVENT = 0x1001,
    NSDK_COMMAND_CODE_ACK = 0x7FFE,
    NSDK_COMMAND_CODE_NACK = 0x7FFF
} nsdk_command_code_t;

typedef enum nsdk_data_rule_kind_t {
    NSDK_DATA_RULE_SUFFIX = 1,
    NSDK_DATA_RULE_PREFIX = 2,
    NSDK_DATA_RULE_HIDE_END = 3,
    NSDK_DATA_RULE_HIDE_MIDDLE = 4,
    NSDK_DATA_RULE_HIDE_START = 5,
    NSDK_DATA_RULE_REPLACE = 7
} nsdk_data_rule_kind_t;

typedef enum nsdk_decoder_module_family_t {
    NSDK_DECODER_MODULE_UNKNOWN = 0,
    NSDK_DECODER_MODULE_NTC06H = 1,
    NSDK_DECODER_MODULE_NT280H = 2,
    NSDK_DECODER_MODULE_NT212X = 3,
    NSDK_DECODER_MODULE_SE4750 = 4
} nsdk_decoder_module_family_t;

typedef enum nsdk_device_model_id_t {
    NSDK_DEVICE_MODEL_UNKNOWN = 0,
    NSDK_DEVICE_MODEL_NT91 = 1,
    NSDK_DEVICE_MODEL_NT1228BC = 4,
    NSDK_DEVICE_MODEL_C750 = 10,
    NSDK_DEVICE_MODEL_CS7501 = 12,
    NSDK_DEVICE_MODEL_CS8501 = 13,
    NSDK_DEVICE_MODEL_CS9501 = 14,
    NSDK_DEVICE_MODEL_C740 = 15
} nsdk_device_model_id_t;

typedef enum nsdk_command_set_kind_t {
    NSDK_COMMAND_SET_UNKNOWN = 0,
    NSDK_COMMAND_SET_MASTER_ONLY = 1,
    NSDK_COMMAND_SET_MODULE_ONLY = 2,
    NSDK_COMMAND_SET_MASTER_WITH_MODULE_INFO = 3
} nsdk_command_set_kind_t;

typedef enum nsdk_master_command_category_t {
    NSDK_MASTER_CATEGORY_UNKNOWN = 0,
    NSDK_MASTER_CATEGORY_POWER = 1,
    NSDK_MASTER_CATEGORY_SCANNING = 2,
    NSDK_MASTER_CATEGORY_FEEDBACK = 3,
    NSDK_MASTER_CATEGORY_WIRELESS = 4,
    NSDK_MASTER_CATEGORY_WIRED = 5,
    NSDK_MASTER_CATEGORY_KEYBOARD_ENCODING = 6,
    NSDK_MASTER_CATEGORY_DATA_PROCESSING = 7,
    NSDK_MASTER_CATEGORY_MODULE = 8,
} nsdk_master_command_category_t;

typedef enum nsdk_master_command_section_t {
    NSDK_MASTER_SECTION_UNKNOWN = 0,
    NSDK_MASTER_SECTION_POWER_SLEEP = 1,
    NSDK_MASTER_SECTION_TIMESTAMP = 2,
    NSDK_MASTER_SECTION_SCAN_MODE = 3,
    NSDK_MASTER_SECTION_SCAN_TIMING = 4,
    NSDK_MASTER_SECTION_FEEDBACK_AUDIO = 5,
    NSDK_MASTER_SECTION_FEEDBACK_BEEP_PATTERN = 6,
    NSDK_MASTER_SECTION_RF_TRANSPORT = 7,
    NSDK_MASTER_SECTION_RF_PAIRING = 8,
    NSDK_MASTER_SECTION_RF_KEYBOARD = 9,
    NSDK_MASTER_SECTION_BLUETOOTH_TRANSPORT = 10,
    NSDK_MASTER_SECTION_BLUETOOTH_BEHAVIOR = 11,
    NSDK_MASTER_SECTION_BLUETOOTH_INFO = 12,
    NSDK_MASTER_SECTION_USB_INTERFACE = 13,
    NSDK_MASTER_SECTION_USB_KEYBOARD = 14,
    NSDK_MASTER_SECTION_KEY_MODIFIER = 15,
    NSDK_MASTER_SECTION_CHARSET = 16,
    NSDK_MASTER_SECTION_RECEIVE_DEVICE = 17,
    NSDK_MASTER_SECTION_KEYBOARD_LAYOUT = 18,
    NSDK_MASTER_SECTION_DATA_RULE = 19,
    NSDK_MASTER_SECTION_OUTPUT_FORMAT = 20,
    NSDK_MASTER_SECTION_REPLACE_RULE = 21,
    NSDK_MASTER_SECTION_TERMINATOR = 22,
    NSDK_MASTER_SECTION_DECODER_MODULE = 23,
} nsdk_master_command_section_t;

typedef enum nsdk_device_form_factor_t {
    NSDK_DEVICE_FORM_UNKNOWN = 0,
    NSDK_DEVICE_FORM_MASTER = 1,
    NSDK_DEVICE_FORM_MASTER_WITH_MODULE = 2,
    NSDK_DEVICE_FORM_SINGLE_MODULE = 3
} nsdk_device_form_factor_t;

typedef enum nsdk_support_status_t {
    NSDK_SUPPORT_UNKNOWN = 0,
    NSDK_SUPPORT_IMPLEMENTED = 1,
    NSDK_SUPPORT_CODE_ONLY = 2,
    NSDK_SUPPORT_VERIFIED = 3
} nsdk_support_status_t;

typedef enum nsdk_nt212x_parameter_kind_t {
    NSDK_NT212X_PARAMETER_UNKNOWN = 0,
    NSDK_NT212X_PARAMETER_BOOL = 1,
    NSDK_NT212X_PARAMETER_ENUM = 2,
    NSDK_NT212X_PARAMETER_UINT8 = 3,
    NSDK_NT212X_PARAMETER_UINT16 = 4,
    NSDK_NT212X_PARAMETER_BYTES_ASCII = 5,
    NSDK_NT212X_PARAMETER_ACTION = 6,
    NSDK_NT212X_PARAMETER_COMPLEX = 7,
    NSDK_NT212X_PARAMETER_CUSTOM = 8
} nsdk_nt212x_parameter_kind_t;

typedef enum nsdk_se4750_parameter_kind_t {
    NSDK_SE4750_PARAMETER_UNKNOWN = 0,
    NSDK_SE4750_PARAMETER_BOOL = 1,
    NSDK_SE4750_PARAMETER_ENUM = 2,
    NSDK_SE4750_PARAMETER_UINT8 = 3,
    NSDK_SE4750_PARAMETER_UINT16 = 4,
    NSDK_SE4750_PARAMETER_BYTES_ASCII = 5
} nsdk_se4750_parameter_kind_t;

typedef enum nsdk_nt280h_parameter_kind_t {
    NSDK_NT280H_PARAMETER_UNKNOWN = 0,
    NSDK_NT280H_PARAMETER_BOOL = 1,
    NSDK_NT280H_PARAMETER_ENUM = 2,
    NSDK_NT280H_PARAMETER_ACTION = 3,
    NSDK_NT280H_PARAMETER_OBJECT = 4
} nsdk_nt280h_parameter_kind_t;

typedef enum nsdk_module_parameter_numeric_input_kind_t {
    NSDK_MODULE_PARAMETER_NUMERIC_INPUT_UNKNOWN = 0,
    NSDK_MODULE_PARAMETER_NUMERIC_INPUT_TENTHS_SECONDS = 1,
    NSDK_MODULE_PARAMETER_NUMERIC_INPUT_UINT8_DECIMAL = 2,
    NSDK_MODULE_PARAMETER_NUMERIC_INPUT_UINT16_MILLISECONDS = 3
} nsdk_module_parameter_numeric_input_kind_t;

typedef enum nsdk_module_parameter_ui_kind_t {
    NSDK_MODULE_PARAMETER_UI_UNKNOWN = 0,
    NSDK_MODULE_PARAMETER_UI_BOOL = 1,
    NSDK_MODULE_PARAMETER_UI_ENUM = 2,
    NSDK_MODULE_PARAMETER_UI_UINT8 = 3,
    NSDK_MODULE_PARAMETER_UI_UINT16 = 4,
    NSDK_MODULE_PARAMETER_UI_BYTES_ASCII = 5,
    NSDK_MODULE_PARAMETER_UI_ACTION = 6,
    NSDK_MODULE_PARAMETER_UI_COMPLEX = 7,
    NSDK_MODULE_PARAMETER_UI_CUSTOM = 8,
    NSDK_MODULE_PARAMETER_UI_OBJECT = 9
} nsdk_module_parameter_ui_kind_t;

typedef enum nsdk_module_taxonomy_kind_t {
    NSDK_MODULE_TAXONOMY_GROUP = 1,
    NSDK_MODULE_TAXONOMY_DOMAIN = 2,
    NSDK_MODULE_TAXONOMY_FAMILY = 3,
    NSDK_MODULE_TAXONOMY_SECTION = 4
} nsdk_module_taxonomy_kind_t;

typedef enum nsdk_module_command_kind_t {
    NSDK_MODULE_COMMAND_RAW_FRAME = 0,
    NSDK_MODULE_COMMAND_READ_VERSION = 1,
    NSDK_MODULE_COMMAND_START_DECODE = 2,
    NSDK_MODULE_COMMAND_STOP_DECODE = 3,
    NSDK_MODULE_COMMAND_READ_PARAMETER = 4,
    NSDK_MODULE_COMMAND_WRITE_PARAMETER = 5,
    NSDK_MODULE_COMMAND_FACTORY_DEFAULTS = 6,
    NSDK_MODULE_COMMAND_SAVE_SETTINGS = 7,
    NSDK_MODULE_COMMAND_SCAN_ENABLE = 8,
    NSDK_MODULE_COMMAND_SCAN_DISABLE = 9,
    NSDK_MODULE_COMMAND_SLEEP = 10,
    NSDK_MODULE_COMMAND_RESET = 11,
    NSDK_MODULE_COMMAND_LED_ON = 12,
    NSDK_MODULE_COMMAND_LED_OFF = 13,
    NSDK_MODULE_COMMAND_ACK = 14,
    NSDK_MODULE_COMMAND_NAK = 15,
    NSDK_MODULE_COMMAND_CAPABILITIES_REQUEST = 16,
    NSDK_MODULE_COMMAND_AIM_ON = 17,
    NSDK_MODULE_COMMAND_AIM_OFF = 18,
    NSDK_MODULE_COMMAND_ILLUMINATION_ON = 19,
    NSDK_MODULE_COMMAND_ILLUMINATION_OFF = 20,
    NSDK_MODULE_COMMAND_CHANGE_ALL_CODE_TYPES = 21,
    NSDK_MODULE_COMMAND_BEEP = 22,
    NSDK_MODULE_COMMAND_PAGER_MOTOR_ACTIVATION = 23
} nsdk_module_command_kind_t;

typedef enum nsdk_transport_type_t {
    NSDK_TRANSPORT_BLE_GATT = 0,
    NSDK_TRANSPORT_USB_HID = 1,
    NSDK_TRANSPORT_USB_SERIAL = 2,
    NSDK_TRANSPORT_SPP_CLASSIC = 3
} nsdk_transport_type_t;

typedef enum nsdk_protocol_channel_kind_t {
    NSDK_PROTOCOL_SCANNER_MASTER = 0,
    NSDK_PROTOCOL_MODULE_PASSTHROUGH = 1
} nsdk_protocol_channel_kind_t;

typedef enum nsdk_basic_device_command_t {
    NSDK_BASIC_DEVICE_GET_VERSION = 1,
    NSDK_BASIC_DEVICE_FACTORY_RESET = 2,
    NSDK_BASIC_DEVICE_WRITE_CUSTOM_DEFAULTS = 3,
    NSDK_BASIC_DEVICE_RESTORE_CUSTOM_DEFAULTS = 4,
    NSDK_BASIC_DEVICE_NORMAL_MODE = 5,
    NSDK_BASIC_DEVICE_STORE_MODE = 6,
    NSDK_BASIC_DEVICE_UPLOAD_MEMORY_DATA = 7,
    NSDK_BASIC_DEVICE_GET_MEMORY_BARCODE_COUNT = 8,
    NSDK_BASIC_DEVICE_UPLOAD_MEMORY_DATA_AND_CLEAR = 9,
    NSDK_BASIC_DEVICE_GET_MEMORY_USAGE = 10,
    NSDK_BASIC_DEVICE_CLEAR_MEMORY = 11,
    NSDK_BASIC_DEVICE_AUTO_STORE_MODE_OFF = 12,
    NSDK_BASIC_DEVICE_AUTO_STORE_MODE_ON = 13
} nsdk_basic_device_command_t;

typedef enum nsdk_session_state_t {
    NSDK_SESSION_IDLE = 0,
    NSDK_SESSION_DISCOVERING = 1,
    NSDK_SESSION_CONNECTING = 2,
    NSDK_SESSION_CONNECTED = 3,
    NSDK_SESSION_READY = 4,
    NSDK_SESSION_BUSY = 5,
    NSDK_SESSION_RECONNECTING = 6,
    NSDK_SESSION_DISCONNECTED = 7,
    NSDK_SESSION_ERROR = 8
} nsdk_session_state_t;

typedef enum nsdk_discovery_failure_code_t {
    NSDK_DISCOVERY_FAILURE_BLE_ADAPTER_DISABLED = 0,
    NSDK_DISCOVERY_FAILURE_BLE_SCANNER_UNAVAILABLE = 1,
    NSDK_DISCOVERY_FAILURE_BLE_FILTERED_SCAN_FAILED = 2,
    NSDK_DISCOVERY_FAILURE_BLE_FILTERED_SCAN_FALLBACK_FAILED = 3,
    NSDK_DISCOVERY_FAILURE_BLE_UNFILTERED_SCAN_FAILED = 4
} nsdk_discovery_failure_code_t;

typedef enum nsdk_ble_scan_issue_t {
    NSDK_BLE_SCAN_ISSUE_ALREADY_STARTED = 0,
    NSDK_BLE_SCAN_ISSUE_REGISTRATION_FAILED = 1,
    NSDK_BLE_SCAN_ISSUE_INTERNAL_ERROR = 2,
    NSDK_BLE_SCAN_ISSUE_FEATURE_UNSUPPORTED = 3,
    NSDK_BLE_SCAN_ISSUE_OUT_OF_HARDWARE_RESOURCES = 4,
    NSDK_BLE_SCAN_ISSUE_THROTTLED = 5,
    NSDK_BLE_SCAN_ISSUE_UNKNOWN = 6
} nsdk_ble_scan_issue_t;

typedef enum nsdk_ble_discovery_scan_mode_t {
    NSDK_BLE_DISCOVERY_SCAN_MODE_FILTERED = 0,
    NSDK_BLE_DISCOVERY_SCAN_MODE_UNFILTERED = 1
} nsdk_ble_discovery_scan_mode_t;

typedef enum nsdk_transport_failure_code_t {
    NSDK_TRANSPORT_FAILURE_UNKNOWN = 0,
    NSDK_TRANSPORT_FAILURE_PLATFORM_STATUS_ERROR = 1,
    NSDK_TRANSPORT_FAILURE_CONNECTION_TIMEOUT = 2,
    NSDK_TRANSPORT_FAILURE_GATT_FAILURE = 3,
    NSDK_TRANSPORT_FAILURE_SERVICE_DISCOVERY_START_FAILED = 4,
    NSDK_TRANSPORT_FAILURE_SERVICE_DISCOVERY_FAILED = 5,
    NSDK_TRANSPORT_FAILURE_NOTIFY_SERVICE_MISSING = 6,
    NSDK_TRANSPORT_FAILURE_NOTIFY_CHARACTERISTIC_MISSING = 7,
    NSDK_TRANSPORT_FAILURE_SET_NOTIFICATION_FAILED = 8,
    NSDK_TRANSPORT_FAILURE_NOTIFY_DESCRIPTOR_MISSING = 9,
    NSDK_TRANSPORT_FAILURE_NOTIFY_DESCRIPTOR_WRITE_FAILED = 10
} nsdk_transport_failure_code_t;

typedef enum nsdk_ble_transport_issue_t {
    NSDK_BLE_TRANSPORT_ISSUE_UNKNOWN = 0,
    NSDK_BLE_TRANSPORT_ISSUE_SERVICE_DISCOVERY_START_FAILED = 1,
    NSDK_BLE_TRANSPORT_ISSUE_SERVICE_DISCOVERY_FAILED = 2,
    NSDK_BLE_TRANSPORT_ISSUE_NOTIFY_SERVICE_MISSING = 3,
    NSDK_BLE_TRANSPORT_ISSUE_NOTIFY_CHARACTERISTIC_MISSING = 4,
    NSDK_BLE_TRANSPORT_ISSUE_SET_NOTIFICATION_FAILED = 5,
    NSDK_BLE_TRANSPORT_ISSUE_NOTIFY_DESCRIPTOR_MISSING = 6,
    NSDK_BLE_TRANSPORT_ISSUE_NOTIFY_DESCRIPTOR_WRITE_FAILED = 7,
    NSDK_BLE_TRANSPORT_ISSUE_CONNECTION_TIMEOUT = 8,
    NSDK_BLE_TRANSPORT_ISSUE_GATT_FAILURE = 9,
    NSDK_BLE_TRANSPORT_ISSUE_PLATFORM_STATUS_ERROR = 10
} nsdk_ble_transport_issue_t;

typedef struct nsdk_scanner_info_t {
    char device_id[128];
    char name[128];
    char serial_number[64];
    char firmware_version[64];
    char hardware_version[64];
    char manufacturer[64];
    char version_format_family[32];
    char version_boot_code[32];
    char version_series_code[32];
    char version_transport_code[32];
    char version_transport_suffix[32];
    char version_wireless_code[16];
    char version_bluetooth_code[16];
    char version_chipset_code[16];
    char version_chipset_suffix[16];
    char version_release_code[32];
    char version_extension_code[64];
} nsdk_scanner_info_t;

typedef struct nsdk_device_capability_summary_t {
    nsdk_device_model_id_t model_id;
    char model_name[64];
    nsdk_command_set_kind_t default_command_set;
    nsdk_device_form_factor_t form_factor;
    nsdk_decoder_module_family_t module_family;
    int32_t supports_basic_device_commands;
    int32_t supports_master_commands;
    int32_t supports_native_module_commands;
    int32_t supports_module_command_bridge;
    int32_t supports_module_commands;
    int32_t supports_scanner_master;
    int32_t supports_module_passthrough;
    nsdk_support_status_t support_status;
} nsdk_device_capability_summary_t;

typedef struct nsdk_session_operation_support_t {
    int32_t supports_refresh_info;
    int32_t supports_initialize_session;
    int32_t supports_get_battery_info;
    int32_t supports_execute_basic_device_commands;
    int32_t supports_execute_text_commands;
    int32_t supports_execute_data_rule_commands;
    int32_t supports_default_module_command_probe;
    int32_t supports_trigger_scan;
    int32_t supports_beep;
    int32_t supports_disable_ack_beep;
    int32_t supports_vibrate_on;
    int32_t supports_vibrate_off;
} nsdk_session_operation_support_t;

typedef struct nsdk_master_command_metadata_t {
    nsdk_master_command_category_t category;
    nsdk_master_command_section_t section;
} nsdk_master_command_metadata_t;

typedef struct nsdk_master_command_category_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_master_command_category_label_t;

typedef struct nsdk_master_command_section_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_master_command_section_label_t;

typedef struct nsdk_master_command_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_master_command_label_t;

typedef struct nsdk_command_descriptor_t {
    char text[64];
    int32_t dangerous;
} nsdk_command_descriptor_t;

typedef struct nsdk_command_code_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_command_code_label_t;

typedef struct nsdk_basic_device_command_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_basic_device_command_label_t;

typedef struct nsdk_data_rule_kind_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_data_rule_kind_label_t;

typedef struct nsdk_module_command_kind_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_module_command_kind_label_t;

typedef struct nsdk_module_action_preset_label_t {
    char action_id[64];
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_module_action_preset_label_t;

typedef struct nsdk_module_test_recommendation_t {
    char recommendation_id[64];
    char title_key[96];
    char title_fallback[96];
    char detail_key[256];
    char detail_fallback[256];
} nsdk_module_test_recommendation_t;

typedef struct nsdk_device_model_profile_t {
    nsdk_device_capability_summary_t capability;
    uint32_t ble_service_uuid_count;
    char ble_service_uuids[4][40];
    uint32_t ble_name_hint_count;
    char ble_name_hints[8][64];
    uint16_t usb_vendor_id;
    uint32_t usb_product_id_count;
    uint16_t usb_product_ids[8];
    int32_t usb_interface_number;
    int32_t usb_hid_report_id;
    int32_t usb_hid_framing_mode;
} nsdk_device_model_profile_t;

typedef struct nsdk_discovery_request_t {
    uint32_t transport_mask;
    nsdk_device_model_id_t selected_model_id;
} nsdk_discovery_request_t;

typedef struct nsdk_connect_request_t {
    const char* device_id;
    nsdk_transport_type_t transport;
    nsdk_protocol_channel_kind_t channel_kind;
    nsdk_device_model_id_t selected_model_id;
    int32_t apply_decoder_module;
} nsdk_connect_request_t;

typedef struct nsdk_discovered_device_t {
    char device_id[128];
    char name[128];
    nsdk_transport_type_t transport;
    nsdk_device_model_id_t model_id;
    char match_reason[64];
    int32_t rssi;
    int32_t rssi_available;
} nsdk_discovered_device_t;

typedef struct nsdk_battery_info_t {
    char raw_text[64];
    char voltage_text[32];
    int32_t percent;
} nsdk_battery_info_t;

typedef struct nsdk_command_response_t {
    char text[512];
    uint8_t text_bytes[512];
    /* Bytes available in text_bytes. This can be smaller than text_full_size. */
    uint32_t text_size;
    /* Full text length reported by core before this fixed-size C ABI buffer truncated it. */
    uint32_t text_full_size;
    char records_text[4096];
    char records_data[4096];
    uint16_t record_offsets[128];
    uint16_t record_lengths[128];
    int32_t record_count;
    int32_t packed_record_count;
    int32_t records_complete;
    uint8_t raw_bytes[64];
    uint32_t raw_size;
    int32_t acknowledged;
    uint32_t module_family;
    uint32_t module_frame_kind;
    uint32_t module_frame_direction;
    uint32_t module_opcode;
    uint32_t module_subcommand;
    uint32_t module_source;
    uint32_t module_status;
    uint8_t module_payload_bytes[512];
    uint32_t module_payload_size;
    uint32_t module_payload_full_size;
    uint32_t module_parameter_id;
    uint8_t module_parameter_value_bytes[512];
    uint32_t module_parameter_value_size;
    uint32_t module_parameter_value_full_size;
    int32_t module_parameter_value_available;
    uint32_t raw_full_size;
} nsdk_command_response_t;

typedef struct nsdk_scan_data_t {
    uint64_t timestamp_ms;
    int32_t barcode_type;
    const char* text;
    const uint8_t* text_bytes;
    uint32_t text_size;
    const uint8_t* raw_bytes;
    uint32_t raw_size;
} nsdk_scan_data_t;

typedef struct nsdk_session_failure_t {
    nsdk_transport_type_t transport;
    nsdk_transport_failure_code_t code;
    nsdk_ble_transport_issue_t ble_issue;
    int32_t platform_error;
} nsdk_session_failure_t;

typedef struct nsdk_discovery_failure_t {
    nsdk_transport_type_t transport;
    nsdk_discovery_failure_code_t code;
    char message[256];
    nsdk_ble_scan_issue_t ble_issue;
    int32_t ble_issue_available;
    int32_t platform_error;
    int32_t platform_error_available;
    int32_t recoverable;
} nsdk_discovery_failure_t;

typedef struct nsdk_nt212x_parameter_metadata_t {
    uint16_t parameter_id;
    char key[16];
    char symbol_name[64];
    char display_name[128];
    char semantic_name[64];
    char group[64];
    char domain_key[64];
    char family_key[64];
    char section_key[64];
    char default_value[64];
    char notes[256];
    char options_json[512];
    nsdk_nt212x_parameter_kind_t kind;
    uint8_t parameter_bytes[2];
    uint32_t parameter_byte_count;
} nsdk_nt212x_parameter_metadata_t;

typedef struct nsdk_nt280h_parameter_metadata_t {
    uint16_t parameter_id;
    uint8_t ex_id;
    uint8_t ex_cmd;
    char key[32];
    char symbol_name[64];
    char display_name[128];
    char semantic_name[64];
    char group[64];
    char domain_key[64];
    char family_key[64];
    char section_key[64];
    char default_value[64];
    char notes[256];
    char options_json[512];
    nsdk_nt280h_parameter_kind_t kind;
    int32_t is_placeholder;
} nsdk_nt280h_parameter_metadata_t;

typedef struct nsdk_se4750_parameter_metadata_t {
    uint32_t parameter_id;
    char key[16];
    char symbol_name[64];
    char display_name[128];
    char semantic_name[64];
    char group[64];
    char domain_key[64];
    char family_key[64];
    char section_key[64];
    char default_value[64];
    char notes[256];
    char options_json[512];
    nsdk_se4750_parameter_kind_t kind;
    uint8_t parameter_bytes[3];
    uint32_t parameter_byte_count;
} nsdk_se4750_parameter_metadata_t;

typedef struct nsdk_ntc06h_setting_metadata_t {
    char key[64];
    char setting_code[32];
    char display_code[32];
    char display_name[128];
    char group[64];
    char domain_key[64];
    char family_key[64];
    char section_key[64];
    char notes[256];
    int32_t requires_save;
    int32_t is_template;
    char template_hint[128];
    char template_example_code[32];
    char template_input_type[32];
    int32_t template_input_width;
    int32_t template_input_min;
    int32_t template_input_max;
} nsdk_ntc06h_setting_metadata_t;

typedef struct nsdk_ntc06h_setting_metadata_view_t {
    const char* key;
    const char* setting_code;
    const char* display_code;
    const char* display_name;
    const char* group;
    const char* domain_key;
    const char* family_key;
    const char* section_key;
    const char* notes;
    int32_t requires_save;
    int32_t is_template;
    const char* template_hint;
    const char* template_example_code;
    const char* template_input_type;
    int32_t template_input_width;
    int32_t template_input_min;
    int32_t template_input_max;
} nsdk_ntc06h_setting_metadata_view_t;

typedef struct nsdk_module_parameter_quick_value_t {
    char payload_hex[16];
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_module_parameter_quick_value_t;

typedef struct nsdk_module_taxonomy_entry_t {
    char key[64];
    int32_t rank;
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_module_taxonomy_entry_t;

typedef struct nsdk_module_parameter_numeric_input_spec_t {
    nsdk_module_parameter_numeric_input_kind_t kind;
    char localization_key[64];
    char fallback_display_name[64];
    int32_t min_value;
    int32_t max_value;
    char step_hint_key[128];
    char step_hint_fallback[128];
} nsdk_module_parameter_numeric_input_spec_t;

typedef struct nsdk_module_parameter_boolean_payload_pair_t {
    char off_payload_hex[16];
    char on_payload_hex[16];
} nsdk_module_parameter_boolean_payload_pair_t;

typedef struct nsdk_module_parameter_enum_label_t {
    char raw_label[128];
    char localization_key[128];
    char fallback_display_name[128];
} nsdk_module_parameter_enum_label_t;

typedef struct nsdk_module_parameter_kind_label_t {
    char localization_key[64];
    char fallback_display_name[64];
} nsdk_module_parameter_kind_label_t;

typedef struct nsdk_module_parameter_title_label_t {
    char raw_title[128];
    char localization_key[128];
    char fallback_display_name[128];
} nsdk_module_parameter_title_label_t;

#ifdef __cplusplus
}
#endif
