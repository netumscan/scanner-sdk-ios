# iOS Integration Guide

## Installation

Add the public SwiftPM package from version `1.0.0`:

```swift
dependencies: [
    .package(
        url: "https://github.com/netumscan/scanner-sdk-ios.git",
        from: "1.0.0"
    )
]
```

Link the `ScannerSDK` product to the application target. The package resolves a
versioned XCFramework and verifies its binary target checksum.

Supported deployment targets:

- iOS 15+
- macOS 12+
- BLE GATT is the supported mobile transport.

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
