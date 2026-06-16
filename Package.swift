// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AlamofireObjC",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "AlamofireObjC", targets: ["AlamofireObjC"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.0")
    ],
    targets: [
        .target(
            name: "AlamofireObjC",
            dependencies: ["Alamofire"],
            path: "Sources/AlamofireObjC"
        ),
        .testTarget(
            name: "AlamofireObjCTests",
            dependencies: ["AlamofireObjC"],
            path: "Tests/AlamofireObjCTests",
            resources: [.copy("Resources")]
        )
    ]
)
