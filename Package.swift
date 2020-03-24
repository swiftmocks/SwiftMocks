// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMocks",
    products: [
        .library(
            name: "SwiftMocks",
            targets: ["SwiftMocks"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftMocks-Assembly",
            path: "Source-Assembly",
            cSettings: [
                .define("NUMBER_OF_TRAMPOLINE_SLOTS", to: "65536"),
                .define("DATA_SECTION_STORAGE_SIZE_KB", to: "1024")
            ]
        ),
        .target(
            name: "SwiftMocks",
            dependencies: ["SwiftMocks-Assembly"],
            path: "Source"
        )
    ]
)
