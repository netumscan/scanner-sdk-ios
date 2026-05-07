#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 安装 Apple BLE transport factory，并启动 bridge。
 这是 Swift / Objective-C 层可直接调用的 C 入口。
 */
void nsdk_apple_ble_install_transport(void);

/**
 启动 Apple BLE runtime，确保 central manager 已初始化。
 */
void nsdk_apple_ble_start_runtime(void);

/**
 停止 Apple BLE runtime，并清空 bridge 持有的 CoreBluetooth 状态。
 */
void nsdk_apple_ble_stop_runtime(void);

/**
 返回当前 Apple BLE central manager 状态，对应 `CBManagerState.rawValue`。
 */
int32_t nsdk_apple_ble_central_state(void);

/**
 返回 Apple BLE discovery failure 通知名。
 */
const char* nsdk_apple_ble_discovery_failure_notification_name(void);

#ifdef __cplusplus
}
#endif
