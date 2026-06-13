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
            url: "https://github.com/netumscan/scanner-sdk-ios/releases/download/v0.1.4/ScannerSDK.xcframework.zip",
            checksum: "b9bf1f9e2ce5b0c3b80124656e6582306084497cd540aaeaaf61383a94bb7443"
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
