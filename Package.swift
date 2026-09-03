// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Mast",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Mast", targets: ["Mast"])
    ],
    targets: [
        .executableTarget(name: "Mast"),
        .testTarget(name: "MastTests", dependencies: ["Mast"])
    ]
)
