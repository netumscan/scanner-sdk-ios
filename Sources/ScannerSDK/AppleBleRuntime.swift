import Foundation
import CNSDK

enum AppleBleRuntime {
    static func installTransport() {
        nsdk_apple_ble_install_transport()
    }

    static func stop() {
        nsdk_apple_ble_stop_runtime()
    }
}
