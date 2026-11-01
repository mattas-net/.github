// swift-tools-version: 5.9
// Minimal SwiftPM package for the self-test job in .github/workflows/checks.yml.
// It exercises ios-ci.yml's test (swift test) and lint (SwiftLint) jobs.
import PackageDescription

let package = Package(
    name: "Fixture",
    products: [
        .library(name: "Fixture", targets: ["Fixture"])
    ],
    targets: [
        .target(name: "Fixture"),
        .testTarget(name: "FixtureTests", dependencies: ["Fixture"])
    ]
)
