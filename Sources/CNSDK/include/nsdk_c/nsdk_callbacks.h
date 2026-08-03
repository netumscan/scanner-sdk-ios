#pragma once

#include "nsdk_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef void (NSDK_C_CALL *nsdk_discovery_failure_callback_t)(
    const nsdk_discovery_failure_t* failure,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_discovered_device_callback_t)(
    const nsdk_discovered_device_t* device,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_session_state_callback_t)(
    nsdk_session_handle_t session,
    nsdk_session_state_t state,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_scan_data_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_scan_data_t* scan_data,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_session_failure_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_session_failure_t* failure,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_session_initialization_stage_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_session_initialization_stage_event_t* event,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_command_trace_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_command_trace_t* trace,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_log_callback_t)(
    nsdk_log_level_t level,
    const char* message,
    void* user_data
);

typedef void (NSDK_C_CALL *nsdk_command_record_callback_t)(
    uint32_t index,
    const char* text,
    uint32_t text_length,
    void* user_data
);

typedef struct nsdk_callbacks_t {
    uint32_t struct_size;
    nsdk_discovery_failure_callback_t discovery_failure_callback;
    void* discovery_failure_user_data;
    nsdk_discovered_device_callback_t discovered_device_callback;
    void* discovered_device_user_data;
    nsdk_session_state_callback_t session_state_callback;
    void* session_state_user_data;
    nsdk_scan_data_callback_t scan_data_callback;
    void* scan_data_user_data;
    nsdk_session_failure_callback_t session_failure_callback;
    void* session_failure_user_data;
    nsdk_session_initialization_stage_callback_t session_initialization_stage_callback;
    void* session_initialization_stage_user_data;
    nsdk_command_trace_callback_t command_trace_callback;
    void* command_trace_user_data;
    nsdk_log_callback_t log_callback;
    void* log_user_data;
    uint32_t reserved[NSDK_STRUCT_RESERVED_FIELD_COUNT];
} nsdk_callbacks_t;

#ifdef __cplusplus
}
#endif
