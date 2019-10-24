// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTPKit",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "HTTPKit",
            targets: ["HTTPKit"]
        ),
        .library(
            name: "RxSupport",
            targets: ["RxSupport"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0-rc.2"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "HTTPKit",
            dependencies: ["Alamofire"],
            path: "HTTPKit"
        ),
        .target(
            name: "RxSupport",
            dependencies: ["HTTPKit", "RxSwift"],
            path: "RxSupport"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
