// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacTidy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacTidy", targets: ["MacTidy"]),
        .library(name: "MacTidyCore", targets: ["MacTidyCore"]),
        .executable(name: "MacTidyCoreTests", targets: ["MacTidyCoreTests"])
    ],
    targets: [
        .target(
            name: "MacTidyCore",
            path: ".",
            exclude: [
                ".agents",
                ".codex",
                ".git",
                "App",
                "dist",
                "docs",
                "README.md",
                "script",
                "Support/Resources",
                "Stores",
                "Tests",
                "Views"
            ],
            sources: [
                "Models",
                "Rules",
                "Services",
                "Support"
            ]
        ),
        .executableTarget(
            name: "MacTidy",
            dependencies: ["MacTidyCore"],
            path: ".",
            exclude: [
                ".agents",
                ".codex",
                ".git",
                "dist",
                "docs",
                "Models",
                "README.md",
                "Rules",
                "script",
                "Services",
                "Support",
                "Tests"
            ],
            sources: [
                "App",
                "Stores",
                "Views"
            ]
        ),
        .executableTarget(
            name: "MacTidyCoreTests",
            dependencies: ["MacTidyCore"],
            path: ".",
            exclude: [
                ".agents",
                ".codex",
                ".git",
                "App",
                "dist",
                "docs",
                "Models",
                "README.md",
                "Rules",
                "script",
                "Services",
                "Stores",
                "Support",
                "Views"
            ],
            sources: [
                "Tests"
            ]
        )
    ]
)
