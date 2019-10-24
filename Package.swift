// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTPKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
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
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "HTTPKit",
            dependencies: ["Alamofire"],
            path: "HTTPKit"
        ),
        .target(
            name: "RxSupport",
            dependencies: ["HTTPKit"],
            path: "RxSupport"
        ),
        .target(
            name: "HandyJSONSupport",
            dependencies: ["HTTPKit"],
            path: "HandyJSONSupport"
        ),
        .target(
            name: "SwiftyJSONSupport",
            dependencies: ["HTTPKit"],
            path: "SwiftyJSONSupport"
        )
    ]
)
