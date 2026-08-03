#import "include/CNSDK.h"
#import <string.h>

#if defined(__GNUC__) || defined(__clang__)
#define CNSDK_STUB_WEAK __attribute__((weak))
#else
#define CNSDK_STUB_WEAK
#endif

#define CNSDK_DISPOSED_STORAGE_TOKEN UINT64_MAX

static nsdk_error_t copy_stub_bytes(
    const uint8_t* source,
    uint32_t source_length,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
) {
    if (out_length == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_length = source_length;
    if (out_bytes == NULL && out_capacity == 0) {
        return NSDK_ERROR_OK;
    }
    if (out_bytes == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    if (out_capacity < source_length) {
        return NSDK_ERROR_BUFFER_TOO_SMALL;
    }
    if (source_length > 0) {
        memcpy(out_bytes, source, source_length);
    }
    return NSDK_ERROR_OK;
}

static void fill_ack_response(nsdk_command_response_t* out_response) {
    if (out_response == NULL) {
        return;
    }
    const uint32_t struct_size = out_response->struct_size;
    memset(out_response, 0, sizeof(*out_response));
    out_response->struct_size = struct_size ? struct_size : sizeof(*out_response);
    out_response->acknowledged = 1;
}

CNSDK_STUB_WEAK int nsdk_cnsdk_stub_symbol(void) {
    return 0;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_discovery_start(const nsdk_discovery_request_t* request) {
    if (request == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_discovery_stop(void) {
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_get_resolved_model_key(
    nsdk_session_handle_t session,
    char* out_model_key,
    uint32_t out_model_key_size
) {
    (void)session;
    if (out_model_key == NULL || out_model_key_size == 0) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    out_model_key[0] = '\0';
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_device_model_count(
    nsdk_transport_type_t transport,
    uint32_t* out_count
) {
    (void)transport;
    if (out_count == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_count = 0;
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_device_model_get_at(
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_supported_device_model_t* out_model
) {
    (void)transport;
    (void)index;
    (void)out_model;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK uint32_t nsdk_abi_version(void) {
    return NSDK_ABI_VERSION;
}

CNSDK_STUB_WEAK int32_t nsdk_abi_is_compatible(uint32_t requested_abi_version) {
    const uint32_t requested_major = (requested_abi_version >> 16) & 0xffu;
    const uint32_t requested_minor = (requested_abi_version >> 8) & 0xffu;
    const uint32_t current_major = (NSDK_ABI_VERSION >> 16) & 0xffu;
    const uint32_t current_minor = (NSDK_ABI_VERSION >> 8) & 0xffu;
    return requested_major == current_major && requested_minor <= current_minor ? 1 : 0;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_read_capability_value(
    nsdk_session_handle_t session,
    const char* entry_key,
    nsdk_capability_value_result_t* out_result
) {
    (void)session;
    (void)entry_key;
    if (out_result == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    const uint32_t struct_size = out_result->struct_size;
    memset(out_result, 0, sizeof(*out_result));
    out_result->struct_size = struct_size ? struct_size : sizeof(*out_result);
    out_result->value_kind = NSDK_CAPABILITY_VALUE_UNKNOWN;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_write_capability_value(
    nsdk_session_handle_t session,
    const nsdk_capability_write_request_t* request,
    nsdk_command_response_t* out_response
) {
    (void)session;
    if (request == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    fill_ack_response(out_response);
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_execute_capability_action(
    nsdk_session_handle_t session,
    const nsdk_capability_action_request_t* request,
    nsdk_command_response_t* out_response
) {
    (void)session;
    if (request == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    fill_ack_response(out_response);
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_get_storage_usage(
    nsdk_session_handle_t session,
    nsdk_storage_usage_t* out_usage
) {
    (void)session;
    if (out_usage == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    const uint32_t struct_size = out_usage->struct_size;
    memset(out_usage, 0, sizeof(*out_usage));
    out_usage->struct_size = struct_size ? struct_size : sizeof(*out_usage);
    strncpy(out_usage->raw_text, "Total Counters=0 Used:0/0s", sizeof(out_usage->raw_text) - 1);
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_set_rtc_timestamp(
    nsdk_session_handle_t session,
    int64_t unix_millis,
    int32_t utc_offset_seconds,
    nsdk_command_response_t* out_response
) {
    (void)session;
    (void)unix_millis;
    (void)utc_offset_seconds;
    fill_ack_response(out_response);
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_apply_data_rule(
    nsdk_session_handle_t session,
    nsdk_data_rule_kind_t kind,
    const uint8_t* primary_bytes,
    uint32_t primary_size,
    const uint8_t* secondary_bytes,
    uint32_t secondary_size,
    nsdk_command_response_t* out_response
) {
    (void)session;
    (void)kind;
    (void)primary_bytes;
    (void)primary_size;
    (void)secondary_bytes;
    (void)secondary_size;
    fill_ack_response(out_response);
    return 0;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_session_set_scan_text_terminator(
    nsdk_session_handle_t session,
    const uint8_t* terminator_bytes,
    uint32_t terminator_size
) {
    (void)session;
    if (terminator_bytes == NULL || terminator_size == 0) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_set_callbacks(const nsdk_callbacks_t* callbacks) {
    (void)callbacks;
    return 0;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_command_response_copy_full_text_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
) {
    if (response == NULL || response->storage_token == CNSDK_DISPOSED_STORAGE_TOKEN) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    return copy_stub_bytes(response->text_bytes, response->text_size, out_bytes, out_capacity, out_length);
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_command_response_copy_full_raw_bytes(
    const nsdk_command_response_t* response,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
) {
    if (response == NULL || response->storage_token == CNSDK_DISPOSED_STORAGE_TOKEN) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    return copy_stub_bytes(response->raw_bytes, response->raw_size, out_bytes, out_capacity, out_length);
}

CNSDK_STUB_WEAK void nsdk_command_response_dispose(
    nsdk_command_response_t* response
) {
    if (response != NULL) {
        response->storage_token = CNSDK_DISPOSED_STORAGE_TOKEN;
    }
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_value_result_copy_full_value_bytes(
    const nsdk_capability_value_result_t* result,
    uint8_t* out_bytes,
    uint32_t out_capacity,
    uint32_t* out_length
) {
    if (result == NULL || result->storage_token == CNSDK_DISPOSED_STORAGE_TOKEN) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    return copy_stub_bytes(result->value_bytes, result->value_size, out_bytes, out_capacity, out_length);
}

CNSDK_STUB_WEAK void nsdk_capability_value_result_dispose(
    nsdk_capability_value_result_t* result
) {
    if (result != NULL) {
        result->storage_token = CNSDK_DISPOSED_STORAGE_TOKEN;
    }
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_domain_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
) {
    (void)model_key;
    (void)transport;
    if (out_count == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_count = 0;
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_domain_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_capability_domain_t* out_domain
) {
    (void)model_key;
    (void)transport;
    (void)index;
    (void)out_domain;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_label_count(
    nsdk_capability_label_kind_t kind,
    uint32_t* out_count
) {
    (void)kind;
    if (out_count == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_count = 0;
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_label_get_at(
    nsdk_capability_label_kind_t kind,
    uint32_t index,
    nsdk_capability_label_t* out_label
) {
    (void)kind;
    (void)index;
    (void)out_label;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_label_find_by_key(
    nsdk_capability_label_kind_t kind,
    const char* owner_key,
    const char* key,
    nsdk_capability_label_t* out_label
) {
    (void)kind;
    (void)owner_key;
    (void)key;
    (void)out_label;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_entry_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
) {
    (void)model_key;
    (void)transport;
    if (out_count == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_count = 0;
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_entry_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_capability_entry_t* out_entry
) {
    (void)model_key;
    (void)transport;
    (void)index;
    (void)out_entry;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_entry_find_by_key(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    nsdk_capability_entry_t* out_entry
) {
    (void)model_key;
    (void)transport;
    (void)entry_key;
    (void)out_entry;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_capability_option_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    uint32_t index,
    nsdk_capability_option_t* out_option
) {
    (void)model_key;
    (void)transport;
    (void)entry_key;
    (void)index;
    (void)out_option;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_setting_code_entry_count(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t* out_count
) {
    (void)model_key;
    (void)transport;
    if (out_count == NULL) {
        return NSDK_ERROR_INVALID_ARGUMENT;
    }
    *out_count = 0;
    return NSDK_ERROR_OK;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_setting_code_entry_get_at(
    const char* model_key,
    nsdk_transport_type_t transport,
    uint32_t index,
    nsdk_setting_code_entry_t* out_entry
) {
    (void)model_key;
    (void)transport;
    (void)index;
    (void)out_entry;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_setting_code_entry_find_by_key(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    nsdk_setting_code_entry_t* out_entry
) {
    (void)model_key;
    (void)transport;
    (void)entry_key;
    (void)out_entry;
    return NSDK_ERROR_NOT_SUPPORTED;
}

CNSDK_STUB_WEAK nsdk_error_t nsdk_build_setting_code(
    const char* model_key,
    nsdk_transport_type_t transport,
    const char* entry_key,
    const uint8_t* value_bytes,
    uint32_t value_size,
    nsdk_setting_code_result_t* out_result
) {
    (void)model_key;
    (void)transport;
    (void)entry_key;
    (void)value_bytes;
    (void)value_size;
    (void)out_result;
    return NSDK_ERROR_NOT_SUPPORTED;
}
