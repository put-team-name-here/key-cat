// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TypingFarm",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TypingFarm",
            path: "Sources/TypingFarm"
        )
    ]
)
