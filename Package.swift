// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "keycat",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KeyCat",
            path: "Sources/KeyCat",
            resources: [
                .copy("Resources/cats"),
                .copy("Resources/fonts"),
                .copy("Resources/grounds"),
                .copy("Resources/gui"),
            ]
        )
    ]
)
