// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notey",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Notey", targets: ["Notey"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Notey",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Notey",
            exclude: ["Info.plist", "Notey.entitlements", "Resources/Assets.xcassets"],
            resources: [
                .copy("Resources/Caveat.ttf")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@loader_path"])
            ]
        ),
        .testTarget(
            name: "NoteyTests",
            dependencies: ["Notey"],
            path: "NoteyTests"
        )
    ]
)
