import Foundation
import CNSDK

@_silgen_name("nsdk_apple_ble_install_transport")
private func nsdkAppleBleInstallTransport()

@_silgen_name("nsdk_apple_ble_stop_runtime")
private func nsdkAppleBleStopRuntime()

enum AppleBleRuntime {
    static func installTransport() {
        nsdkAppleBleInstallTransport()
    }

    static func stop() {
        nsdkAppleBleStopRuntime()
    }
}
