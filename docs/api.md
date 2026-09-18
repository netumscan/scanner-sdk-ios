# Apple API Starting Points

`ScannerSDK.shared` provides:

- read-only `version`
- initialization and shutdown
- discovery and failure streams
- connection
- model profiles and capability metadata

`ScannerSession` provides:

- state and scan-event streams
- device information, battery, and resolved model
- capability enumeration
- capability read, write, and action operations
- disconnect

Handle `ScannerError` by its stable SDK code and operation. Observe asynchronous
SDK/session failures as part of the application lifecycle.

Native ABI compatibility is enforced automatically before SDK initialization.
See [Apple native compatibility](ios.md#native-compatibility) for supported
XCFramework slices and load-versus-version troubleshooting.

## Unfiltered BLE discovery

BLE discovery returns all platform observations with a valid device ID, including unnamed and unrelated devices. There is no legacy filtering switch. `selectedModelKey` is retained but ignored for discovery; model and match reason remain empty. Non-BLE discovery is unchanged.

`DiscoveredDevice` adds defaulted `advertisementName`, `serviceUuids`, `manufacturerData`, `serviceData`, and nullable `connectable`. UUIDs are complete and lowercase. Manufacturer map keys are Bluetooth company IDs, not USB VIDs; payload excludes the two-byte company ID. Service Data bytes are unchanged. A missing field means unknown and does not clear cached data. Each scan clears the cache; first observations and changes (including weaker RSSI) are emitted, identical updates are suppressed. Platform coverage and available fields can differ.

Use a map keyed by `deviceId`. Show unnamed devices with a display placeholder, keep every device, and disable connect only when `connectable == false`. Candidates are an app hint: name or advertised name contains `Scanner` / `Barcode`, case-insensitively. Sort candidates first, then RSSI descending (unknown last), lowercase name and device ID. Never auto-connect or probe unfamiliar devices. User-initiated connection still validates GATT and runs the existing session flow.

The wrapper uses the independent C discovery v2 callback and copies borrowed data before asynchronous delivery. Ship it with the matching new native library and rebuild callers; old v1 C callbacks remain supported with their original fields and now receive all BLE devices too. Rollback requires reverting the version, not toggling a filter mode.

```swift
func candidate(_ d: DiscoveredDevice) -> Bool {
    [d.name, d.advertisementName].contains {
        $0.lowercased().contains("scanner") || $0.lowercased().contains("barcode")
    }
}
let canConnect = device.connectable != false
let label = device.name.isEmpty ? "Unnamed device" : device.name
```
