// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorLiveActivities",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorLiveActivities",
            targets: ["LiveActivitiesPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "LiveActivitiesPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                "LiveActivitiesKit"
            ],
            path: "ios/Plugin"),
        .target(
            name: "LiveActivitiesKit",
            path: "ios/LiveActivitiesKit")
    ]
)