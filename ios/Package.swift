// swift-tools-version: 6.0
// Local package with all the logic testable without an iPhone (Foundation only).
import PackageDescription

let package = Package(
    name: "StepTellerCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "StepTellerCore", targets: ["StepTellerCore"])
    ],
    targets: [
        .target(name: "StepTellerCore"),
        .testTarget(name: "StepTellerCoreTests", dependencies: ["StepTellerCore"])
    ]
)
