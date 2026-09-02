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
