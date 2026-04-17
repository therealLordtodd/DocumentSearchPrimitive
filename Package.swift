// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DocumentSearchPrimitive",
    platforms: [
        .macOS(.v13),
        .iOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "DocumentSearchPrimitive",
            targets: ["DocumentSearchPrimitive"]
        ),
    ],
    dependencies: [
        .package(path: "../ContentModelPrimitive"),
        .package(path: "../ReaderChromeThemePrimitive"),
    ],
    targets: [
        .target(
            name: "DocumentSearchPrimitive",
            dependencies: [
                .product(name: "ContentModelPrimitive", package: "ContentModelPrimitive"),
                .product(name: "ReaderChromeThemePrimitive", package: "ReaderChromeThemePrimitive"),
            ]
        ),
        .testTarget(
            name: "DocumentSearchPrimitiveTests",
            dependencies: ["DocumentSearchPrimitive"]
        ),
    ]
)
