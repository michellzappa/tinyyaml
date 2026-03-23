// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyYAML",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../Packages/TinyKit"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "TinyYAML",
            dependencies: [
                "TinyKit",
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/TinyYAML",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
