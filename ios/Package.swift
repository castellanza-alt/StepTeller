// swift-tools-version: 6.0
// Pacchetto locale con tutta la logica testabile senza iPhone (solo Foundation).
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
