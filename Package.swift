// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncSequenceExtensions",
    platforms: [.iOS(.v14), .macOS(.v11), .watchOS(.v7), .tvOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AsyncSequenceExtensions",
            targets: ["AsyncSequenceExtensions"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AsyncSequenceExtensions",
            swiftSettings: [.unsafeFlags(["-Xfrontend", "-enable-experimental-concurrency"], nil)]
        ),
        .testTarget(
            name: "AsyncSequenceExtensionsTests",
            dependencies: ["AsyncSequenceExtensions"],
            resources: [.copy("Resources/TestFile.md")],
            swiftSettings: [.unsafeFlags(["-Xfrontend", "-enable-experimental-concurrency"], nil)]
        )
    ]
)
