// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuFold",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MenuFold", targets: ["MenuFold"])
    ],
    targets: [
        .executableTarget(
            name: "MenuFold",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(name: "MenuFoldTests", dependencies: ["MenuFold"])
    ]
)
