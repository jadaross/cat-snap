// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkRender",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MarkRender", path: "Sources/MarkRender")
    ]
)
