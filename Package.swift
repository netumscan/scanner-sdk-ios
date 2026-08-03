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
            url: "https://github.com/netumscan/scanner-sdk-ios/releases/download/v1.0.0/ScannerSDK.xcframework.zip",
            checksum: "7a218086671b12531d1e32978717691adf6485d3e7e3ea0a5c7572189a0ffb2d"
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
