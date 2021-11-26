// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ACINetworking",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "ACINetworking",
            targets: ["ACINetworking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.0"))
    ],
    targets: [
        .target(
            name: "ACINetworking",
            dependencies: ["Alamofire"]),
        .testTarget(
            name: "ACINetworkingTests",
            dependencies: ["ACINetworking"]),
    ],
    swiftLanguageVersions: [.v5]
)
