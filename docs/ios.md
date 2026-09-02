# iOS Integration Guide

## Installation

Add the public SwiftPM package from version `1.1.0`:

```swift
dependencies: [
    .package(
        url: "https://github.com/netumscan/scanner-sdk-ios.git",
        from: "1.1.0"
    )
]
```

Link the `ScannerSDK` product to the application target. The package resolves a
versioned XCFramework and verifies its binary target checksum.

Supported deployment targets:

- iOS 15+
- macOS 12+
- BLE GATT is the supported mobile transport.

## Native Compatibility

The versioned XCFramework contains these supported slices:

| Target | Architectures | Deployment target |
| --- | --- | --- |
| iOS device | `arm64` | iOS 15 |
| iOS Simulator | `arm64`, `x86_64` | iOS 15 |
| macOS | `arm64` | macOS 12 |

An XCFramework slice controls platform and CPU compatibility. The Scanner SDK
C ABI separately controls whether the Swift wrapper can safely call the native
runtime. `ScannerSDK.shared.initialize()` automatically checks required ABI
`0x010000` before native initialization and callback installation.

Applications do not need to call the low-level C ABI. Do not combine Swift
sources or C headers from one release with an XCFramework from another release.
Use the complete SwiftPM tag and its checksum-pinned binary target.

If integration fails:

- A SwiftPM checksum or binary-target resolution error means the URL, version,
  checksum, and downloaded archive do not describe the same release.
- An Xcode platform or architecture error means the target is outside the
  slices above. Mac Catalyst is not currently supported.
- `native ABI mismatch required=... actual=...` means the Swift wrapper/C
  headers and XCFramework are mixed across releases. Restore one complete tag;
  do not bypass the check.
- A `ScannerError` returned by native initialization means slice and ABI checks
  succeeded; diagnose it by stable code and operation.

## Required Info.plist Description

The host application must provide a Bluetooth usage description:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connect to scanner devices and receive barcode data.</string>
```

## Recommended Flow

1. Read `ScannerSDK.shared.version` for diagnostics.
2. Initialize the SDK.
3. Observe discovery and failure streams.
4. Start BLE discovery with the selected scanner model.
5. Connect and wait for the session to become Ready.
6. Observe `scanEvents` and session failures.
7. Serialize configuration commands.
8. Stop discovery and disconnect when the feature is no longer active.

Use `ScanEvent.textBytes` and `rawBytes` as source data and decode with the
business-selected charset. Do not rely only on the convenience `text` value.

## Recovery

Treat Bluetooth power changes, permission denial, and disconnects as session
termination. Clear stale UI state, wait for Bluetooth/permission recovery, then
discover and connect again. Do not reuse a terminated session.
