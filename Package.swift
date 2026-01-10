// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ContextualSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // The main library that includes everything
        .library(
            name: "ContextualSDK",
            targets: ["ContextualSDK", "ContextualIntelligence", "ContextualUI"]
        ),
    ],
    targets: [
        // 1. CORE: Protocols, Models, and lightweight logic
        .target(
            name: "ContextualSDK",
            dependencies: []
        ),
        
        // 2. INTELLIGENCE: AI Implementations (Apple Intelligence, Regex, etc.)
        .target(
            name: "ContextualIntelligence",
            dependencies: ["ContextualSDK"]
        ),
        
        // 3. UI: SwiftUI Components and Renderers
        .target(
            name: "ContextualUI",
            dependencies: ["ContextualSDK"]
        ),
        
        // Tests
        .testTarget(
            name: "ContextualSDKTests",
            dependencies: ["ContextualSDK", "ContextualIntelligence"]
        ),
    ]
)
