// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "EraseUI",
	defaultLocalization: "en",
	platforms: [.iOS(.v18)],
	products: [
		.library(name: "EraseUI", targets: ["EraseUI"]),
	],
	dependencies: [
		.package(path: "../EraseKit"),
	],
	targets: [
		.target(name: "EraseUI", dependencies: ["EraseKit"]),
	]
)
