// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SAPHANAApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SAPHANAAppCore",
            targets: ["SAPHANAAppCore"]
        )
    ],
    dependencies: [
        // SAP BTP SDK for iOS (Swift Package Manager distribution)
        .package(
            url: "https://github.com/SAP/cloud-sdk-ios.git",
            from: "9.2.0"
        )
    ],
    targets: [
        .target(
            name: "SAPHANAAppCore",
            dependencies: [
                .product(name: "SAPFoundation", package: "cloud-sdk-ios", condition: .when(platforms: [.iOS])),
                .product(name: "SAPOData", package: "cloud-sdk-ios", condition: .when(platforms: [.iOS])),
                .product(name: "SAPFiori", package: "cloud-sdk-ios", condition: .when(platforms: [.iOS]))
            ],
            path: ".",
            exclude: ["App/Info.plist", "README.md", "Package.swift"],
            sources: [
                "Configuration",
                "Core",
                "Models",
                "ViewModels",
                "Views",
                "App"
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

