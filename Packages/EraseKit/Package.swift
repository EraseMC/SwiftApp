// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "EraseKit",
	defaultLocalization: "en",
	platforms: [.iOS(.v18), .macOS(.v15)],
	products: [
		.library(name: "EraseKit", targets: ["EraseKit"]),
	],
	targets: [
		.target(name: "EraseKit"),
		.testTarget(name: "EraseKitTests", dependencies: ["EraseKit"]),
	]
)
