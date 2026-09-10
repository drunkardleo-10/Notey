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
    targets: [
        .executableTarget(
            name: "Notey",
            path: "Notey",
            exclude: ["Info.plist", "Notey.entitlements"]
        ),
        .testTarget(
            name: "NoteyTests",
            dependencies: ["Notey"],
            path: "NoteyTests"
        )
    ]
)
