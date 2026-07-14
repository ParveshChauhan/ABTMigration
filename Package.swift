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
        .library(
            name: "Flagship",
            targets: ["Flagship"]
        )
    ],
    dependencies: [
        .package(path: "../../VWO_FME/IOS/vwo-fme-ios-sdk")
    ],
    targets: [
        .target(
            name: "Flagship",
            dependencies: [
                .product(name: "Wingify-FME", package: "vwo-fme-ios-sdk")
            ],
            path: "FlagShip/Source"
        )
    ]
)
