// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "BTCScanner",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/anquii/RIPEMD160.git", from: "1.0.0"),
            .package(url: "https://github.com/attaswift/BigInt", from: "5.3.0")

    ],
    targets: [
        .executableTarget(
            name: "BTCScanner",
            dependencies: ["RIPEMD160","BigInt"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"])
            ]
        )
    ]
) 