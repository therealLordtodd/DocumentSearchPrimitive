// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DocumentSearchPrimitive",
    platforms: [
        .macOS(.v13),
        .iOS(.v15),
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
        .package(path: "../SearchPrimitive"),
    ],
    targets: [
        .target(
            name: "DocumentSearchPrimitive",
            dependencies: [
                .product(name: "ContentModelPrimitive", package: "ContentModelPrimitive"),
                .product(name: "ReaderChromeThemePrimitive", package: "ReaderChromeThemePrimitive"),
                .product(name: "SearchPrimitive", package: "SearchPrimitive"),
            ]
        ),
        .testTarget(
            name: "DocumentSearchPrimitiveTests",
            dependencies: ["DocumentSearchPrimitive"]
        ),
    ]
)
