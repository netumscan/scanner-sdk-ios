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
            url: "https://github.com/netumscan/scanner-sdk-ios/releases/download/v2.0.0/ScannerSDK.xcframework.zip",
            checksum: "75d09217d3d4f86eb2d9255cb9883c27d806bac2f12b34a79fd277b226bcfdf2"
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
