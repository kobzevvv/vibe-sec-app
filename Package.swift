// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeSec",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "VibeSec",
            path: "Sources/VibeSec"
        )
    ]
)
