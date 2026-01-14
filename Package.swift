// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SampleVault",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SampleVault",
            targets: ["SampleVault"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.0")
    ],
    targets: [
        .executableTarget(
            name: "SampleVault",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "AudioKit", package: "AudioKit")
            ],
            path: "SampleVault/Sources"
        )
    ]
)
