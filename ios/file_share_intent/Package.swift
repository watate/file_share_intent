// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "file_share_intent",
    platforms: [
        .iOS("12.0"),
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "file_share_intent",
            targets: ["file_share_intent", "file_share_intent_objc"]
        ),
    ],
    dependencies: [
        // Add any dependencies here if needed
    ],
    targets: [
        .target(
            name: "file_share_intent_objc",
            dependencies: [],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "file_share_intent",
            dependencies: ["file_share_intent_objc"]
        ),
    ]
)