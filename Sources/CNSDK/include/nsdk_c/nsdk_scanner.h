#pragma once

#include "nsdk_types.h"
#include "nsdk_nt212x_parameters.h"
#include "nsdk_callbacks.h"

#ifdef __cplusplus
extern "C" {
#endif

nsdk_error_t nsdk_initialize(void);
nsdk_error_t nsdk_shutdown(void);
const char* nsdk_version(void);

nsdk_error_t nsdk_start_discovery(uint32_t transport_mask);
nsdk_error_t nsdk_start_discovery_ex(const nsdk_discovery_request_t* request);
nsdk_error_t nsdk_stop_discovery(void);

nsdk_error_t nsdk_connect_with_request(
    const nsdk_connect_request_t* request,
    nsdk_session_handle_t* out_session
);

nsdk_error_t nsdk_disconnect(nsdk_session_handle_t session);
nsdk_error_t nsdk_wait_until_ready(nsdk_session_handle_t session, uint32_t timeout_ms);

nsdk_error_t nsdk_refresh_info(
    nsdk_session_handle_t session,
    nsdk_scanner_info_t* out_info
);
nsdk_error_t nsdk_initialize_session(
    nsdk_session_handle_t session,
    int32_t apply_model_config,
    nsdk_scanner_info_t* out_info,
    nsdk_battery_info_t* out_battery_info,
    int32_t* out_model_config_applied
);
nsdk_error_t nsdk_get_cached_info(
    nsdk_session_handle_t session,
    nsdk_scanner_info_t* out_info
);
nsdk_error_t nsdk_get_resolved_model_id(
    nsdk_session_handle_t session,
    nsdk_device_model_id_t* out_model_id
);
nsdk_error_t nsdk_set_preferred_model(
    nsdk_session_handle_t session,
    nsdk_device_model_id_t model_id,
    int32_t apply_decoder_module
);
nsdk_error_t nsdk_get_device_capability_summary(
    nsdk_session_handle_t session,
    nsdk_device_capability_summary_t* out_summary
);
nsdk_error_t nsdk_get_session_operation_support(
    nsdk_session_handle_t session,
    nsdk_session_operation_support_t* out_support
);
nsdk_error_t nsdk_get_device_model_profile(
    nsdk_device_model_id_t model_id,
    nsdk_device_model_profile_t* out_profile
);
nsdk_error_t nsdk_get_device_model_name(
    nsdk_device_model_id_t model_id,
    char* out_name,
    uint32_t out_name_size
);
nsdk_error_t nsdk_get_battery_info(
    nsdk_session_handle_t session,
    nsdk_battery_info_t* out_info
);
nsdk_error_t nsdk_get_cached_battery_info(
    nsdk_session_handle_t session,
    nsdk_battery_info_t* out_info
);
nsdk_error_t nsdk_execute_basic_device_command(
    nsdk_session_handle_t session,
    nsdk_basic_device_command_t command,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_execute_master_command(
    nsdk_session_handle_t session,
    nsdk_master_command_id_t command_id,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_execute_text_command(
    nsdk_session_handle_t session,
    const char* command_text,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_execute_data_rule_command(
    nsdk_session_handle_t session,
    nsdk_data_rule_kind_t kind,
    const uint8_t* primary_bytes,
    uint32_t primary_size,
    const uint8_t* secondary_bytes,
    uint32_t secondary_size,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_execute_module_command(
    nsdk_session_handle_t session,
    nsdk_decoder_module_family_t family,
    nsdk_module_command_kind_t kind,
    uint32_t parameter_id,
    const uint8_t* payload_bytes,
    uint32_t payload_size,
    int32_t persist,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_execute_module_raw_frame(
    nsdk_session_handle_t session,
    nsdk_decoder_module_family_t family,
    const uint8_t* frame_bytes,
    uint32_t frame_size,
    nsdk_command_response_t* out_response
);
nsdk_error_t nsdk_can_execute_master_command(
    nsdk_session_handle_t session,
    nsdk_master_command_id_t command_id,
    int32_t* out_supported
);
nsdk_error_t nsdk_get_command_code_descriptor(
    nsdk_command_code_t command_code,
    nsdk_command_descriptor_t* out_descriptor
);
nsdk_error_t nsdk_get_basic_device_command_descriptor(
    nsdk_basic_device_command_t command_id,
    nsdk_command_descriptor_t* out_descriptor
);
nsdk_error_t nsdk_get_command_code_label(
    nsdk_command_code_t command_code,
    nsdk_command_code_label_t* out_label
);
nsdk_error_t nsdk_get_basic_device_command_label(
    nsdk_basic_device_command_t command_id,
    nsdk_basic_device_command_label_t* out_label
);
nsdk_error_t nsdk_get_data_rule_kind_label(
    nsdk_data_rule_kind_t kind,
    nsdk_data_rule_kind_label_t* out_label
);
nsdk_error_t nsdk_get_master_command_descriptor(
    nsdk_master_command_id_t command_id,
    nsdk_command_descriptor_t* out_descriptor
);
nsdk_error_t nsdk_get_master_command_metadata(
    nsdk_master_command_id_t command_id,
    nsdk_master_command_metadata_t* out_metadata
);
nsdk_error_t nsdk_get_master_command_label(
    nsdk_master_command_id_t command_id,
    nsdk_master_command_label_t* out_label
);
nsdk_error_t nsdk_get_master_command_category_label(
    nsdk_master_command_category_t category,
    nsdk_master_command_category_label_t* out_label
);
nsdk_error_t nsdk_get_master_command_section_label(
    nsdk_master_command_section_t section,
    nsdk_master_command_section_label_t* out_label
);
nsdk_error_t nsdk_is_module_command_dangerous(
    nsdk_module_command_kind_t kind,
    int32_t* out_dangerous
);
nsdk_error_t nsdk_get_module_command_kind_label(
    nsdk_module_command_kind_t kind,
    nsdk_module_command_kind_label_t* out_label
);
nsdk_error_t nsdk_get_module_action_preset_label(
    const char* action_id,
    nsdk_module_action_preset_label_t* out_label,
    int32_t* out_supported
);
uint32_t nsdk_module_test_recommendation_count(nsdk_decoder_module_family_t family);
nsdk_error_t nsdk_module_test_recommendation_get_at(
    nsdk_decoder_module_family_t family,
    uint32_t index,
    nsdk_module_test_recommendation_t* out_recommendation
);
nsdk_error_t nsdk_can_execute_module_command(
    nsdk_session_handle_t session,
    nsdk_decoder_module_family_t family,
    nsdk_module_command_kind_t kind,
    uint32_t parameter_id,
    int32_t persist,
    int32_t* out_supported
);
nsdk_error_t nsdk_can_execute_default_module_command_probe(
    nsdk_session_handle_t session,
    nsdk_decoder_module_family_t family,
    int32_t* out_supported
);
nsdk_error_t nsdk_set_scan_terminator(
    nsdk_session_handle_t session,
    const uint8_t* terminator_bytes,
    uint32_t terminator_size
);
nsdk_error_t nsdk_command_response_get_record(
    const nsdk_command_response_t* response,
    uint32_t index,
    char* out_text,
    uint32_t out_capacity,
    uint32_t* out_length
);

/* Copies the bytes currently available in response->text_bytes.
 * out_length receives response->text_size. Compare text_size with text_full_size
 * to detect fixed-buffer truncation in this C ABI response object.
 */
nsdk_error_t nsdk_command_response_copy_text_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
nsdk_error_t nsdk_command_response_copy_raw_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
nsdk_error_t nsdk_command_response_copy_module_payload_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
nsdk_error_t nsdk_command_response_copy_module_parameter_value_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
nsdk_error_t nsdk_command_response_for_each_record(
    const nsdk_command_response_t* response,
    nsdk_command_record_callback_t callback,
    void* user_data
);
nsdk_error_t nsdk_scan_data_copy_text_bytes(
    const nsdk_scan_data_t* scan_data,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
nsdk_error_t nsdk_scan_data_copy_raw_bytes(
    const nsdk_scan_data_t* scan_data,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
);
uint32_t nsdk_nt212x_parameter_count(void);
nsdk_error_t nsdk_nt212x_parameter_get_at(
    uint32_t index,
    nsdk_nt212x_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_nt212x_parameter_find_by_id(
    uint16_t parameter_id,
    nsdk_nt212x_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_nt212x_parameter_find_by_key(
    const char* key,
    nsdk_nt212x_parameter_metadata_t* out_metadata
);
uint32_t nsdk_nt280h_parameter_count(void);
nsdk_error_t nsdk_nt280h_parameter_get_at(
    uint32_t index,
    nsdk_nt280h_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_nt280h_parameter_find_by_id(
    uint16_t parameter_id,
    nsdk_nt280h_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_nt280h_parameter_find_by_key(
    const char* key,
    nsdk_nt280h_parameter_metadata_t* out_metadata
);
uint32_t nsdk_se4750_parameter_count(void);
nsdk_error_t nsdk_se4750_parameter_get_at(
    uint32_t index,
    nsdk_se4750_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_se4750_parameter_find_by_id(
    uint32_t parameter_id,
    nsdk_se4750_parameter_metadata_t* out_metadata
);
nsdk_error_t nsdk_se4750_parameter_find_by_key(
    const char* key,
    nsdk_se4750_parameter_metadata_t* out_metadata
);
uint32_t nsdk_ntc06h_setting_count(void);
nsdk_error_t nsdk_ntc06h_setting_get_at(
    uint32_t index,
    nsdk_ntc06h_setting_metadata_t* out_metadata
);
nsdk_error_t nsdk_ntc06h_setting_find_by_key(
    const char* key,
    nsdk_ntc06h_setting_metadata_t* out_metadata
);
nsdk_error_t nsdk_ntc06h_setting_find_by_code(
    const char* setting_code,
    nsdk_ntc06h_setting_metadata_t* out_metadata
);
nsdk_ntc06h_setting_metadata_view_t nsdk_ntc06h_setting_metadata_make_view(
    const nsdk_ntc06h_setting_metadata_t* metadata
);
uint32_t nsdk_module_parameter_quick_value_count(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id
);
nsdk_error_t nsdk_module_parameter_quick_value_get_at(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id,
    uint32_t index,
    nsdk_module_parameter_quick_value_t* out_value
);
nsdk_error_t nsdk_get_module_parameter_numeric_input_spec(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id,
    nsdk_module_parameter_numeric_input_spec_t* out_spec,
    int32_t* out_supported
);
nsdk_error_t nsdk_get_module_parameter_boolean_payload_pair(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id,
    nsdk_module_parameter_boolean_payload_pair_t* out_pair,
    int32_t* out_supported
);
nsdk_error_t nsdk_get_module_parameter_enum_label(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id,
    const char* raw_label,
    nsdk_module_parameter_enum_label_t* out_label,
    int32_t* out_supported
);
nsdk_error_t nsdk_get_module_parameter_kind_label(
    nsdk_module_parameter_ui_kind_t kind,
    nsdk_module_parameter_kind_label_t* out_label,
    int32_t* out_supported
);
nsdk_error_t nsdk_get_module_parameter_title_label(
    nsdk_decoder_module_family_t family,
    uint32_t parameter_id,
    const char* alias_name,
    const char* display_name,
    nsdk_module_parameter_title_label_t* out_label,
    int32_t* out_supported
);
uint32_t nsdk_module_taxonomy_entry_count(nsdk_module_taxonomy_kind_t kind);
nsdk_error_t nsdk_module_taxonomy_entry_get_at(
    nsdk_module_taxonomy_kind_t kind,
    uint32_t index,
    nsdk_module_taxonomy_entry_t* out_entry
);

nsdk_error_t nsdk_trigger_scan(nsdk_session_handle_t session);
nsdk_error_t nsdk_beep(nsdk_session_handle_t session);
nsdk_error_t nsdk_disable_ack_beep(nsdk_session_handle_t session);
nsdk_error_t nsdk_vibrate_on(nsdk_session_handle_t session);
nsdk_error_t nsdk_vibrate_off(nsdk_session_handle_t session);

nsdk_error_t nsdk_set_discovery_callback(
    nsdk_discovery_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_set_discovery_failure_callback(
    nsdk_discovery_failure_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_make_android_ble_discovery_unavailable_failure(
    int32_t bluetooth_enabled,
    int32_t scanner_available,
    nsdk_discovery_failure_t* out_failure
);

nsdk_error_t nsdk_make_android_ble_discovery_fallback_start_failure(
    nsdk_discovery_failure_t* out_failure
);

nsdk_error_t nsdk_make_android_ble_async_discovery_failure(
    nsdk_ble_discovery_scan_mode_t mode,
    int32_t platform_error_code,
    int32_t fallback_started,
    nsdk_discovery_failure_t* out_failure
);

nsdk_error_t nsdk_make_apple_ble_discovery_failure_for_central_state(
    int32_t central_state,
    nsdk_discovery_failure_t* out_failure,
    int32_t* out_has_failure
);

nsdk_error_t nsdk_set_discovered_device_callback(
    nsdk_discovered_device_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_set_session_state_callback(
    nsdk_session_state_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_set_scan_data_callback(
    nsdk_scan_data_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_set_session_failure_callback(
    nsdk_session_failure_callback_t callback,
    void* user_data
);

nsdk_error_t nsdk_set_log_callback(
    nsdk_log_callback_t callback,
    void* user_data
);

#ifdef __cplusplus
}
#endif

#undef NSDK_C_DEPRECATED
