// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flagship",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v10_14),
        .watchOS(.v7)
    ],
    products: [
        /// ABTasty-only SDK (does not link Wingify-FME — smaller binary).
        .library(
            name: "Flagship",
            targets: ["Flagship"]
        ),
        /// Dual-engine add-on: link **in addition to** `Flagship` when you need Wingify.
        .library(
            name: "FlagshipWingify",
            targets: ["FlagshipWingify"]
        )
    ],
    dependencies: [
        .package(path: "../../VWO_FME/IOS/vwo-fme-ios-sdk")
    ],
    targets: [
        .target(
            name: "Flagship",
            dependencies: [],
            path: "FlagShip/Source",
            exclude: ["WingifyBridge"]
        ),
        .target(
            name: "FlagshipWingify",
            dependencies: [
                "Flagship",
                .product(name: "Wingify-FME", package: "vwo-fme-ios-sdk")
            ],
            path: "FlagShip/Source/WingifyBridge"
        )
    ]
)
