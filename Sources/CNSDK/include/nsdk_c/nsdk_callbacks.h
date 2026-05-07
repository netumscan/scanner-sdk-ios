#pragma once

#include "nsdk_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*nsdk_discovery_callback_t)(
    const char* device_id,
    const char* name,
    nsdk_transport_type_t transport,
    void* user_data
);

typedef void (*nsdk_discovery_failure_callback_t)(
    const nsdk_discovery_failure_t* failure,
    void* user_data
);

typedef void (*nsdk_discovered_device_callback_t)(
    const nsdk_discovered_device_t* device,
    void* user_data
);

typedef void (*nsdk_session_state_callback_t)(
    nsdk_session_handle_t session,
    nsdk_session_state_t state,
    void* user_data
);

typedef void (*nsdk_scan_data_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_scan_data_t* scan_data,
    void* user_data
);

typedef void (*nsdk_session_failure_callback_t)(
    nsdk_session_handle_t session,
    const nsdk_session_failure_t* failure,
    void* user_data
);

typedef void (*nsdk_log_callback_t)(
    int32_t level,
    const char* message,
    void* user_data
);

typedef void (*nsdk_command_record_callback_t)(
    uint32_t index,
    const char* text,
    uint32_t text_length,
    void* user_data
);

#ifdef __cplusplus
}
#endif
