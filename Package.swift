// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "keycat",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KeyCat",
            path: "Sources/KeyCat",
            exclude: ["Assets.xcassets"],
            resources: [
                .copy("Resources/cats"),
                .copy("Resources/fonts"),
                .copy("Resources/grounds"),
                .copy("Resources/gui"),
                .copy("Resources/fabrics"),
            ]
        ),
        .testTarget(
            name: "KeyCatTests",
            dependencies: ["KeyCat"],
            path: "Tests/KeyCatTests"
        )
    ]
)
