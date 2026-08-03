#pragma once

#include <stdint.h>
#include <string.h>

#define NSDK_ABI_VERSION_MAJOR 1u
#define NSDK_ABI_VERSION_MINOR 0u
#define NSDK_ABI_VERSION_PATCH 0u
#define NSDK_PACK_VERSION(major, minor, patch) \
    ((((uint32_t)(major) & 0xffu) << 16) | (((uint32_t)(minor) & 0xffu) << 8) | ((uint32_t)(patch) & 0xffu))
#define NSDK_ABI_VERSION NSDK_PACK_VERSION(NSDK_ABI_VERSION_MAJOR, NSDK_ABI_VERSION_MINOR, NSDK_ABI_VERSION_PATCH)

#define NSDK_STRUCT_RESERVED_FIELD_COUNT 4u
#if defined(_WIN32) || defined(__CYGWIN__)
/* Exported functions use the default cdecl; callback pointer types keep it explicit. */
#  define NSDK_C_CALL __cdecl
#  if defined(NSDK_C_BUILD_SHARED)
#    define NSDK_C_API __declspec(dllexport)
#  elif defined(NSDK_C_SHARED)
#    define NSDK_C_API __declspec(dllimport)
#  else
#    define NSDK_C_API
#  endif
#  define NSDK_C_DEPRECATED __declspec(deprecated)
#elif defined(__GNUC__) || defined(__clang__)
#  if defined(NSDK_C_BUILD_SHARED)
#    define NSDK_C_API __attribute__((visibility("default")))
#  else
#    define NSDK_C_API
#  endif
#  define NSDK_C_CALL
#  define NSDK_C_DEPRECATED __attribute__((deprecated))
#else
#  define NSDK_C_API
#  define NSDK_C_CALL
#  define NSDK_C_DEPRECATED
#endif

#define NSDK_INIT_STRUCT(value)       \
    do {                              \
        memset(&(value), 0, sizeof(value)); \
        (value).struct_size = (uint32_t)sizeof(value); \
    } while (0)

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t nsdk_error_t;
typedef uint64_t nsdk_session_handle_t;

enum {
    NSDK_ERROR_OK = 0,
    NSDK_ERROR_INVALID_ARGUMENT = 1,
    NSDK_ERROR_NOT_INITIALIZED = 2,
    NSDK_ERROR_NOT_SUPPORTED = 3,
    NSDK_ERROR_BUSY = 4,
    NSDK_ERROR_TIMEOUT = 5,
    NSDK_ERROR_TRANSPORT_OPEN_FAILED = 6,
    NSDK_ERROR_TRANSPORT_WRITE_FAILED = 7,
    NSDK_ERROR_DISCOVERY_FAILED = 8,
    NSDK_ERROR_CONNECT_FAILED = 9,
    NSDK_ERROR_DISCONNECT_FAILED = 10,
    NSDK_ERROR_PROTOCOL_ERROR = 11,
    NSDK_ERROR_DEVICE_NOT_READY = 12,
    NSDK_ERROR_BUFFER_TOO_SMALL = 13,
    NSDK_ERROR_INTERNAL_ERROR = -1
};

typedef int32_t nsdk_data_rule_kind_t;
enum {
    NSDK_DATA_RULE_SUFFIX = 1,
    NSDK_DATA_RULE_PREFIX = 2,
    NSDK_DATA_RULE_HIDE_END = 3,
    NSDK_DATA_RULE_HIDE_MIDDLE = 4,
    NSDK_DATA_RULE_HIDE_START = 5,
    NSDK_DATA_RULE_REPLACE = 7
};

typedef int32_t nsdk_device_support_status_t;
enum {
    NSDK_DEVICE_SUPPORT_UNKNOWN = 0,
    NSDK_DEVICE_SUPPORT_CODE_ONLY = 1,
    NSDK_DEVICE_SUPPORT_VERIFIED = 2
};

typedef int32_t nsdk_log_level_t;
enum {
    NSDK_LOG_DEBUG = 0,
    NSDK_LOG_INFO = 1,
    NSDK_LOG_WARN = 2,
    NSDK_LOG_ERROR = 3
};

typedef int32_t nsdk_model_config_policy_t;
enum {
    NSDK_MODEL_CONFIG_POLICY_AUTO = 0,
    NSDK_MODEL_CONFIG_POLICY_DISABLED = 1,
    NSDK_MODEL_CONFIG_POLICY_ENABLED = 2
};

typedef int32_t nsdk_capability_value_kind_t;
enum {
    NSDK_CAPABILITY_VALUE_UNKNOWN = 0,
    NSDK_CAPABILITY_VALUE_BOOLEAN = 1,
    NSDK_CAPABILITY_VALUE_ENUM = 2,
    NSDK_CAPABILITY_VALUE_UINT8 = 3,
    NSDK_CAPABILITY_VALUE_UINT16 = 4,
    NSDK_CAPABILITY_VALUE_BYTES_ASCII = 5,
    NSDK_CAPABILITY_VALUE_ACTION = 6,
    NSDK_CAPABILITY_VALUE_COMPLEX = 7,
    NSDK_CAPABILITY_VALUE_CUSTOM = 8,
    NSDK_CAPABILITY_VALUE_OBJECT = 9,
    NSDK_CAPABILITY_VALUE_TEMPLATE = 10
};

typedef int32_t nsdk_capability_entry_kind_t;
enum {
    NSDK_CAPABILITY_ENTRY_SETTING = 1,
    NSDK_CAPABILITY_ENTRY_ACTION = 2
};

typedef int32_t nsdk_capability_entry_source_t;
enum {
    NSDK_CAPABILITY_ENTRY_SOURCE_MODULE = 0,
    NSDK_CAPABILITY_ENTRY_SOURCE_MASTER = 1,
    NSDK_CAPABILITY_ENTRY_SOURCE_SESSION = 2
};

typedef int32_t nsdk_capability_entry_availability_t;
enum {
    NSDK_CAPABILITY_ENTRY_AVAILABLE = 0,
    NSDK_CAPABILITY_ENTRY_UNAVAILABLE_IN_CURRENT_TRANSPORT = 1,
    NSDK_CAPABILITY_ENTRY_UNSUPPORTED_BY_PROFILE = 2,
    NSDK_CAPABILITY_ENTRY_SHADOWED_BY_PREFERRED_ROUTE = 3
};

typedef int32_t nsdk_capability_label_kind_t;
enum {
    NSDK_CAPABILITY_LABEL_DOMAIN = 1,
    NSDK_CAPABILITY_LABEL_FAMILY = 2,
    NSDK_CAPABILITY_LABEL_SECTION = 3,
    NSDK_CAPABILITY_LABEL_GROUP = 4,
    NSDK_CAPABILITY_LABEL_SETTING = 5,
    NSDK_CAPABILITY_LABEL_ACTION = 6,
    NSDK_CAPABILITY_LABEL_ENUM_VALUE = 7
};

typedef int32_t nsdk_command_trace_kind_t;
enum {
    NSDK_COMMAND_TRACE_UNKNOWN = 0,
    NSDK_COMMAND_TRACE_MASTER = 2,
    NSDK_COMMAND_TRACE_TEXT = 3,
    NSDK_COMMAND_TRACE_DATA_RULE = 4,
    NSDK_COMMAND_TRACE_CAPABILITY_READ = 5,
    NSDK_COMMAND_TRACE_CAPABILITY_WRITE = 6,
    NSDK_COMMAND_TRACE_SCAN_CONTROL = 7,
    NSDK_COMMAND_TRACE_CAPABILITY_ACTION = 8
};

typedef int32_t nsdk_transport_type_t;
enum {
    NSDK_TRANSPORT_BLE_GATT = 0,
    NSDK_TRANSPORT_USB_HID = 1,
    NSDK_TRANSPORT_USB_SERIAL = 2,
    NSDK_TRANSPORT_SPP_CLASSIC = 3
};

typedef int32_t nsdk_capability_risk_level_t;
enum {
    NSDK_CAPABILITY_RISK_NORMAL = 0,
    NSDK_CAPABILITY_RISK_DESTRUCTIVE = 1,
    NSDK_CAPABILITY_RISK_CONNECTIVITY = 2,
    NSDK_CAPABILITY_RISK_DATA_LOSS = 3
};

typedef int32_t nsdk_setting_code_payload_kind_t;
enum {
    NSDK_SETTING_CODE_PAYLOAD_UNKNOWN = 0,
    NSDK_SETTING_CODE_PAYLOAD_TEXT_COMMAND = 1,
    NSDK_SETTING_CODE_PAYLOAD_MODULE_SETTING_CODE = 2,
    NSDK_SETTING_CODE_PAYLOAD_DATA_RULE_TEXT_COMMAND = 3,
    NSDK_SETTING_CODE_PAYLOAD_TEMPLATE = 4,
    NSDK_SETTING_CODE_PAYLOAD_COMMAND_ONLY = 5,
    NSDK_SETTING_CODE_PAYLOAD_UNAVAILABLE = 6
};

typedef int32_t nsdk_setting_code_symbology_t;
enum {
    NSDK_SETTING_CODE_SYMBOLOGY_UNKNOWN = 0,
    NSDK_SETTING_CODE_SYMBOLOGY_CODE128 = 1,
    NSDK_SETTING_CODE_SYMBOLOGY_QR_CODE = 2,
    NSDK_SETTING_CODE_SYMBOLOGY_DATA_MATRIX = 3,
    NSDK_SETTING_CODE_SYMBOLOGY_PDF417 = 4
};

typedef int32_t nsdk_session_state_t;
enum {
    NSDK_SESSION_IDLE = 0,
    NSDK_SESSION_DISCOVERING = 1,
    NSDK_SESSION_CONNECTING = 2,
    NSDK_SESSION_CONNECTED = 3,
    NSDK_SESSION_READY = 4,
    NSDK_SESSION_BUSY = 5,
    NSDK_SESSION_RECONNECTING = 6,
    NSDK_SESSION_DISCONNECTED = 7,
    NSDK_SESSION_ERROR = 8
};

typedef int32_t nsdk_session_initialization_stage_t;
enum {
    NSDK_SESSION_INITIALIZATION_STARTED = 0,
    NSDK_SESSION_INITIALIZATION_READING_DEVICE_INFO = 1,
    NSDK_SESSION_INITIALIZATION_READING_BATTERY = 2,
    NSDK_SESSION_INITIALIZATION_READING_CAPABILITY_SUMMARY = 3,
    NSDK_SESSION_INITIALIZATION_READING_OPERATION_SUPPORT = 4,
    NSDK_SESSION_INITIALIZATION_COMPLETED = 5,
    NSDK_SESSION_INITIALIZATION_FAILED = 6
};

typedef int32_t nsdk_discovery_failure_code_t;
enum {
    NSDK_DISCOVERY_FAILURE_BLE_ADAPTER_DISABLED = 0,
    NSDK_DISCOVERY_FAILURE_BLE_SCANNER_UNAVAILABLE = 1,
    NSDK_DISCOVERY_FAILURE_BLE_FILTERED_SCAN_FAILED = 2,
    NSDK_DISCOVERY_FAILURE_BLE_FILTERED_SCAN_FALLBACK_FAILED = 3,
    NSDK_DISCOVERY_FAILURE_BLE_UNFILTERED_SCAN_FAILED = 4,
    NSDK_DISCOVERY_FAILURE_BLE_PERMISSION_DENIED = 5
};

typedef int32_t nsdk_ble_scan_issue_t;
enum {
    NSDK_BLE_SCAN_ISSUE_ALREADY_STARTED = 0,
    NSDK_BLE_SCAN_ISSUE_REGISTRATION_FAILED = 1,
    NSDK_BLE_SCAN_ISSUE_INTERNAL_ERROR = 2,
    NSDK_BLE_SCAN_ISSUE_FEATURE_UNSUPPORTED = 3,
    NSDK_BLE_SCAN_ISSUE_OUT_OF_HARDWARE_RESOURCES = 4,
    NSDK_BLE_SCAN_ISSUE_THROTTLED = 5,
    NSDK_BLE_SCAN_ISSUE_UNKNOWN = 6
};

typedef int32_t nsdk_transport_issue_t;
enum {
    NSDK_TRANSPORT_ISSUE_UNKNOWN = 0,
    NSDK_TRANSPORT_ISSUE_PLATFORM_ERROR = 1,
    NSDK_TRANSPORT_ISSUE_CONNECTION_TIMEOUT = 2,
    NSDK_TRANSPORT_ISSUE_BLE_GATT_FAILURE = 3,
    NSDK_TRANSPORT_ISSUE_BLE_SERVICE_DISCOVERY_START_FAILED = 4,
    NSDK_TRANSPORT_ISSUE_BLE_SERVICE_DISCOVERY_FAILED = 5,
    NSDK_TRANSPORT_ISSUE_BLE_NOTIFY_SERVICE_MISSING = 6,
    NSDK_TRANSPORT_ISSUE_BLE_NOTIFY_CHARACTERISTIC_MISSING = 7,
    NSDK_TRANSPORT_ISSUE_BLE_NOTIFICATION_ENABLE_FAILED = 8,
    NSDK_TRANSPORT_ISSUE_BLE_NOTIFY_DESCRIPTOR_MISSING = 9,
    NSDK_TRANSPORT_ISSUE_BLE_NOTIFY_DESCRIPTOR_WRITE_FAILED = 10
};

typedef struct nsdk_scanner_info_t {
    uint32_t struct_size;
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
    char bluetooth_name[128];
    char bluetooth_firmware_version[64];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_scanner_info_t;

typedef struct nsdk_device_capability_summary_t {
    uint32_t struct_size;
    char model_key[64];
    char model_name[64];
    int32_t supports_scan_control;
    int32_t supports_device_commands;
    int32_t supports_settings_read;
    int32_t supports_settings_write;
    int32_t supports_data_rules;
    int32_t supports_battery;
    nsdk_device_support_status_t support_status;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_device_capability_summary_t;

typedef struct nsdk_device_model_profile_t {
    uint32_t struct_size;
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
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_device_model_profile_t;

typedef struct nsdk_supported_device_model_t {
    uint32_t struct_size;
    char model_key[64];
    char model_name[64];
    char series_key[32];
    char series_name[64];
    nsdk_device_model_profile_t profile;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_supported_device_model_t;

typedef struct nsdk_session_operation_support_t {
    uint32_t struct_size;
    int32_t supports_refresh_info;
    int32_t supports_initialize_session;
    int32_t supports_get_battery_info;
    int32_t supports_apply_data_rule;
    int32_t supports_trigger_scan;
    int32_t supports_set_ack_beep_enabled;
    int32_t supports_set_vibration_enabled;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_session_operation_support_t;

typedef struct nsdk_data_rule_kind_label_t {
    uint32_t struct_size;
    char localization_key[64];
    char fallback_display_name[64];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_data_rule_kind_label_t;

typedef struct nsdk_discovery_request_t {
    uint32_t struct_size;
    uint32_t transport_mask;
    char selected_model_key[64];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_discovery_request_t;

typedef struct nsdk_connect_request_t {
    uint32_t struct_size;
    const char* device_id;
    nsdk_transport_type_t transport;
    char selected_model_key[64];
    nsdk_model_config_policy_t model_config_policy;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_connect_request_t;

typedef struct nsdk_discovered_device_t {
    uint32_t struct_size;
    char device_id[128];
    char name[128];
    nsdk_transport_type_t transport;
    char model_key[64];
    char match_reason[64];
    int32_t rssi;
    int32_t rssi_available;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_discovered_device_t;

typedef struct nsdk_battery_info_t {
    uint32_t struct_size;
    char raw_text[64];
    char voltage_text[32];
    int32_t percent;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_battery_info_t;

typedef struct nsdk_storage_usage_t {
    uint32_t struct_size;
    int32_t barcode_count;
    int32_t used;
    int32_t capacity;
    int32_t remaining;
    char raw_text[128];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_storage_usage_t;

typedef struct nsdk_command_response_t {
    uint32_t struct_size;
    char text[512];
    uint8_t text_bytes[512];
    uint32_t text_size;
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
    uint32_t raw_full_size;
    int32_t acknowledged;
    uint64_t storage_token;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_command_response_t;

typedef struct nsdk_capability_value_result_t {
    uint32_t struct_size;
    nsdk_capability_value_kind_t value_kind;
    uint8_t value_bytes[512];
    uint32_t value_size;
    uint32_t value_full_size;
    int32_t value_available;
    uint64_t storage_token;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_value_result_t;

typedef struct nsdk_capability_write_request_t {
    uint32_t struct_size;
    const char* entry_key;
    const uint8_t* value_bytes;
    uint32_t value_size;
    int32_t persist;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_write_request_t;

typedef struct nsdk_capability_action_request_t {
    uint32_t struct_size;
    const char* entry_key;
    const uint8_t* value_bytes;
    uint32_t value_size;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_action_request_t;

typedef struct nsdk_command_trace_t {
    uint32_t struct_size;
    uint64_t timestamp_ms;
    uint64_t duration_ms;
    uint64_t trace_id;
    nsdk_session_handle_t session;
    nsdk_transport_type_t transport;
    char resolved_model_key[64];
    nsdk_command_trace_kind_t kind;
    nsdk_error_t error_code;
    int32_t acknowledged;
    int32_t request_available;
    int32_t response_available;
    char operation[64];
    char entry_key[96];
    char semantic_key[96];
    char domain_key[64];
    nsdk_capability_entry_source_t route_source;
    char request_text[256];
    char request_hex[512];
    char response_text[512];
    char response_hex[512];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_command_trace_t;

typedef struct nsdk_capability_domain_t {
    uint32_t struct_size;
    char key[64];
    char display_name[128];
    char localization_key[128];
    uint32_t sort_order;
    int32_t visible_by_default;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_domain_t;

typedef struct nsdk_capability_option_t {
    uint32_t struct_size;
    char value[64];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_option_t;

typedef struct nsdk_capability_label_t {
    uint32_t struct_size;
    nsdk_capability_label_kind_t kind;
    char key[96];
    char owner_key[96];
    char display_name[128];
    char localization_key[128];
    uint32_t rank;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_label_t;

typedef struct nsdk_localization_entry_t {
    uint32_t struct_size;
    char key[128];
    char locale[32];
    char text[256];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_localization_entry_t;

typedef struct nsdk_capability_entry_t {
    uint32_t struct_size;
    char entry_key[96];
    nsdk_capability_entry_kind_t kind;
    char domain_key[64];
    char group_key[64];
    char family_key[64];
    char section_key[64];
    char semantic_key[96];
    char default_value[64];
    char notes[256];
    nsdk_capability_entry_source_t source;
    uint32_t transport_scopes;
    nsdk_capability_entry_availability_t availability;
    int32_t route_priority;
    /* Non-zero means show in default capability lists. Available entries with zero here are advanced. */
    int32_t visible_by_default;
    int32_t supports_read;
    int32_t supports_write;
    int32_t supports_execute;
    int32_t requires_value;
    nsdk_capability_value_kind_t value_kind;
    /* Risk is independent of default visibility; non-normal entries should be confirmed by UI. */
    nsdk_capability_risk_level_t risk_level;
    /* Display hint. Machine-readable subset: "Integer range <min>-<max>" with decimal closed bounds. */
    char value_hint[128];
    uint32_t option_count;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_capability_entry_t;

typedef struct nsdk_setting_code_entry_t {
    uint32_t struct_size;
    char code_key[128];
    char entry_key[96];
    nsdk_capability_entry_kind_t capability_kind;
    nsdk_capability_entry_source_t source;
    char semantic_key[96];
    char domain_key[64];
    nsdk_capability_value_kind_t value_kind;
    nsdk_capability_risk_level_t risk_level;
    int32_t requires_value;
    int32_t supports_static_code;
    int32_t supports_template_code;
    nsdk_setting_code_payload_kind_t payload_kind;
    char value[64];
    /* Display hint. Machine-readable subset: "Integer range <min>-<max>" with decimal closed bounds. */
    char value_hint[128];
    char payload_text[512];
    uint32_t payload_size;
    uint32_t payload_full_size;
    nsdk_setting_code_symbology_t symbology;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_setting_code_entry_t;

typedef struct nsdk_setting_code_result_t {
    uint32_t struct_size;
    nsdk_setting_code_payload_kind_t payload_kind;
    char text[512];
    uint8_t text_bytes[512];
    uint32_t text_size;
    uint32_t text_full_size;
    nsdk_setting_code_symbology_t symbology;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_setting_code_result_t;

typedef struct nsdk_scan_data_t {
    uint32_t struct_size;
    uint64_t timestamp_ms;
    int32_t barcode_type;
    const char* text;
    const uint8_t* text_bytes;
    uint32_t text_size;
    const uint8_t* raw_bytes;
    uint32_t raw_size;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_scan_data_t;

typedef struct nsdk_session_failure_t {
    uint32_t struct_size;
    nsdk_transport_type_t transport;
    nsdk_transport_issue_t issue;
    int32_t platform_error;
    int32_t platform_error_available;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_session_failure_t;

typedef struct nsdk_session_initialization_stage_event_t {
    uint32_t struct_size;
    char selected_model_key[64];
    nsdk_session_initialization_stage_t stage;
    uint64_t timestamp_ms;
    uint64_t trace_id;
    int32_t success;
    nsdk_error_t error_code;
    char message[128];
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_session_initialization_stage_event_t;

typedef struct nsdk_discovery_failure_t {
    uint32_t struct_size;
    nsdk_transport_type_t transport;
    nsdk_discovery_failure_code_t code;
    char message[256];
    nsdk_ble_scan_issue_t ble_issue;
    int32_t ble_issue_available;
    int32_t platform_error;
    int32_t platform_error_available;
    int32_t recoverable;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_discovery_failure_t;

#ifdef __cplusplus
}
#endif
