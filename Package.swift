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
            url: "https://github.com/netumscan/scanner-sdk-ios/releases/download/v2.2.0/ScannerSDK.xcframework.zip",
            checksum: "f0a2a41ade5bf593f3034b6e8b51578c677d3e239569d0e0c1814b7b95515c7b"
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
            resources: [
                .process("Resources"),
            ],
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
