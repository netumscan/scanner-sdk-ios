#pragma once

#include "nsdk_callbacks.h"
#include "nsdk_types.h"

#ifdef __cplusplus
extern "C" {
#endif

NSDK_C_API nsdk_error_t nsdk_initialize(void);
NSDK_C_API nsdk_error_t nsdk_shutdown(void);
NSDK_C_API const char* nsdk_version(void);
NSDK_C_API uint32_t nsdk_abi_version(void);
NSDK_C_API int32_t nsdk_abi_is_compatible(uint32_t requested_abi_version);
NSDK_C_API const char* nsdk_error_name(nsdk_error_t code);
NSDK_C_API const char* nsdk_error_message(nsdk_error_t code);

NSDK_C_API nsdk_error_t nsdk_discovery_start(const nsdk_discovery_request_t* request);
NSDK_C_API nsdk_error_t nsdk_discovery_stop(void);

NSDK_C_API nsdk_error_t nsdk_session_connect(
    const nsdk_connect_request_t* request,
    nsdk_session_handle_t* out_session
);

NSDK_C_API nsdk_error_t nsdk_session_disconnect(nsdk_session_handle_t session);
NSDK_C_API nsdk_error_t nsdk_session_wait_until_ready(nsdk_session_handle_t session, uint32_t timeout_ms);

NSDK_C_API nsdk_error_t nsdk_session_refresh_scanner_info(
    nsdk_session_handle_t session,
    nsdk_scanner_info_t* out_info
);
NSDK_C_API nsdk_error_t nsdk_session_initialize(
    nsdk_session_handle_t session,
    nsdk_scanner_info_t* out_info,
    nsdk_battery_info_t* out_battery_info,
    int32_t* out_model_config_applied
);
NSDK_C_API nsdk_error_t nsdk_session_get_cached_scanner_info(
    nsdk_session_handle_t session,
    nsdk_scanner_info_t* out_info
);
NSDK_C_API nsdk_error_t nsdk_session_get_resolved_model_key(
    nsdk_session_handle_t session,
    char* out_model_key,
    uint32_t out_model_key_size
);
NSDK_C_API nsdk_error_t nsdk_session_get_device_capability_summary(
    nsdk_session_handle_t session,
    nsdk_device_capability_summary_t* out_summary
);
NSDK_C_API nsdk_error_t nsdk_session_get_operation_support(
    nsdk_session_handle_t session,
    nsdk_session_operation_support_t* out_support
);
NSDK_C_API nsdk_error_t nsdk_device_model_get_profile(
    const char* model_key,
    nsdk_device_model_profile_t* out_profile
);
NSDK_C_API nsdk_error_t nsdk_device_model_count(
    nsdk_transport_type_t transport,
    uint32_t* out_count
);
NSDK_C_API nsdk_error_t nsdk_device_model_get_at(
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_supported_device_model_t* out_model
);
NSDK_C_API nsdk_error_t nsdk_session_get_battery_info(
    nsdk_session_handle_t session,
    nsdk_battery_info_t* out_info
);
NSDK_C_API nsdk_error_t nsdk_session_get_cached_battery_info(
    nsdk_session_handle_t session,
    nsdk_battery_info_t* out_info
);
NSDK_C_API nsdk_error_t nsdk_session_get_storage_usage(
    nsdk_session_handle_t session,
    nsdk_storage_usage_t* out_usage
);
NSDK_C_API nsdk_error_t nsdk_session_set_rtc_timestamp(
    nsdk_session_handle_t session,
    int64_t unix_millis,
    int32_t utc_offset_seconds,
    nsdk_command_response_t* out_response
);
NSDK_C_API nsdk_error_t nsdk_session_apply_data_rule(
    nsdk_session_handle_t session,
    nsdk_data_rule_kind_t kind,
    const uint8_t* primary_bytes,
    uint32_t primary_size,
    const uint8_t* secondary_bytes,
    uint32_t secondary_size,
    nsdk_command_response_t* out_response
);
NSDK_C_API nsdk_error_t nsdk_session_read_capability_value(
    nsdk_session_handle_t session,
    const char* entry_key,
    nsdk_capability_value_result_t* out_result
);
NSDK_C_API nsdk_error_t nsdk_session_write_capability_value(
    nsdk_session_handle_t session,
    const nsdk_capability_write_request_t* request,
    nsdk_command_response_t* out_response
);
NSDK_C_API nsdk_error_t nsdk_session_execute_capability_action(
    nsdk_session_handle_t session,
    const nsdk_capability_action_request_t* request,
    nsdk_command_response_t* out_response
);
NSDK_C_API nsdk_error_t nsdk_data_rule_kind_get_label(
    nsdk_data_rule_kind_t kind,
    nsdk_data_rule_kind_label_t* out_label
);
NSDK_C_API nsdk_error_t nsdk_session_set_scan_text_terminator(
    nsdk_session_handle_t session,
    const uint8_t* terminator_bytes,
    uint32_t terminator_size
);
NSDK_C_API nsdk_error_t nsdk_command_response_copy_full_text_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
NSDK_C_API nsdk_error_t nsdk_command_response_copy_full_raw_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
NSDK_C_API void nsdk_command_response_dispose(
    nsdk_command_response_t* response
);
NSDK_C_API nsdk_error_t nsdk_capability_value_result_copy_full_value_bytes(
    const nsdk_capability_value_result_t* result,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
NSDK_C_API void nsdk_capability_value_result_dispose(
    nsdk_capability_value_result_t* result
);
NSDK_C_API nsdk_error_t nsdk_command_response_for_each_record(
    const nsdk_command_response_t* response,
    nsdk_command_record_callback_t callback,
    void* user_data
);
// Enumerates SDK-owned UTF-8 localization resources. These APIs do not require nsdk_initialize.
NSDK_C_API nsdk_error_t nsdk_localization_entry_count(uint32_t* out_count);
NSDK_C_API nsdk_error_t nsdk_localization_entry_get_at(
    uint32_t index,
    nsdk_localization_entry_t* out_entry
);
NSDK_C_API nsdk_error_t nsdk_capability_domain_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
);
NSDK_C_API nsdk_error_t nsdk_capability_domain_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_capability_domain_t* out_domain
);
NSDK_C_API nsdk_error_t nsdk_capability_label_count(
    nsdk_capability_label_kind_t kind,
    uint32_t* out_count
);
NSDK_C_API nsdk_error_t nsdk_capability_label_get_at(
    nsdk_capability_label_kind_t kind,
    uint32_t index,
    nsdk_capability_label_t* out_label
);
NSDK_C_API nsdk_error_t nsdk_capability_label_find_by_key(
    nsdk_capability_label_kind_t kind,
    const char* owner_key,
    const char* key,
    nsdk_capability_label_t* out_label
);
NSDK_C_API nsdk_error_t nsdk_capability_entry_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
);
NSDK_C_API nsdk_error_t nsdk_capability_entry_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_capability_entry_t* out_entry
);
NSDK_C_API nsdk_error_t nsdk_capability_entry_find_by_key(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    nsdk_capability_entry_t* out_entry
);
NSDK_C_API nsdk_error_t nsdk_capability_option_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    uint32_t index,
    nsdk_capability_option_t* out_option
);
NSDK_C_API nsdk_error_t nsdk_setting_code_entry_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
);
NSDK_C_API nsdk_error_t nsdk_setting_code_entry_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_setting_code_entry_t* out_entry
);
NSDK_C_API nsdk_error_t nsdk_setting_code_entry_find_by_key(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    nsdk_setting_code_entry_t* out_entry
);
NSDK_C_API nsdk_error_t nsdk_build_setting_code(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    const uint8_t* value_bytes,
    uint32_t value_size,
    nsdk_setting_code_result_t* out_result
);
NSDK_C_API nsdk_error_t nsdk_set_callbacks(const nsdk_callbacks_t* callbacks);

#ifdef __cplusplus
}
#endif

#undef NSDK_C_DEPRECATED
#undef NSDK_C_API
