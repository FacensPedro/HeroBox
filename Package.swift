// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "HeroBox", platforms: [.iOS(.v16), .macOS("10.15.4")], products: [.library(name: "XboxMedia", targets: ["XboxMedia"])], targets: [.target(name: "XboxMedia"), .testTarget(name: "XboxMediaTests", dependencies: ["XboxMedia"])])
