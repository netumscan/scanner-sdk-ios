// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScannerSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "ScannerSDK",
            targets: ["ScannerSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "ScannerSDKBinary",
            url: "https://github.com/netumscan/scanner-sdk-ios/releases/download/v0.1.2/ScannerSDK.xcframework.zip",
            checksum: "5d48604b2fae49955309c2e1af6363a9f96b0400b5413d92e83628ca3c55fdaf"
        ),
        .target(
            name: "CNSDK",
            dependencies: ["ScannerSDKBinary"],
            path: "Sources/CNSDK",
            publicHeadersPath: "include"
        ),
        .target(
            name: "ScannerSDK",
            dependencies: [
                "CNSDK",
                "ScannerSDKBinary",
            ],
            path: "Sources/ScannerSDK",
            linkerSettings: [
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("Foundation"),
            ]
        ),
        .testTarget(
            name: "ScannerSDKTests",
            dependencies: ["ScannerSDK"],
            path: "Tests/ScannerSDKTests"
        ),
    ]
)
