// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SerialPi",
    dependencies: [
        .package(
            name: "Files",
            url: "https://github.com/johnsundell/files.git",
            from: "4.0.0"
            )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SerialPi",
            dependencies: ["SerialPiCore"]
            ),
        .target(name: "SerialPiCore",
            dependencies: ["Files"]
            ),
        .testTarget(
            name: "SerialPiTests",
            dependencies: ["SerialPi"]),
    ]
)
