// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let libmpvTargets = [
    "Avcodec",
    "Avfilter",
    "Avformat",
    "Avutil",
    "Mbedcrypto",
    "Mbedtls",
    "Mbedx509",
    "Mpv",
    "Swresample",
    "Swscale"
]

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.3/libmpv-xcframeworks_v0.7.3_macos-universal-audio-full"
let libmpvChecksums = [
    "Avcodec": "b27203e230c1fa2bef61ac9429c0a639170346572bc30deb13d7189d02255dac",
    "Avfilter": "bf37e0c7ec7adf0733c80348bbf5d22c6103ea46ed13e6df1a127e2b0d3b00a4",
    "Avformat": "75e4a7b9887a2efd3e6bd7474b7965c39548358e2764f2abeb49454b7605b1fb",
    "Avutil": "1b3f6626a2ff8f76fc731fc9d71955c2b33e0eb6e5fb1d03fff193ed19e17fed",
    "Mbedcrypto": "853a401c0eb4d1e101077d7da33db3c703b49b8b00e448b0b5e0d0e31d85c88c",
    "Mbedtls": "2b0ae39c2400955dbbca577af2c2ce0928a848943c0ea8efc346ee1196c327b7",
    "Mbedx509": "6cd2b014a6ba1ce045d7b3b80485d65c6426b40001db339b4ad8090ff941a776",
    "Mpv": "10e486fb9f3cf4a6af1caceb5ecd60c6ce8b9d3a60eb9e2d01070e18e7dbb493",
    "Swresample": "a83cd8f90e254702970448533a1e30a7745e1f2f138911eb9937fe84da2c66b4",
    "Swscale": "b1771fd76e0cb90d5bc7716d1cd964c603bcc8fc0013fa1c40abfef5cc67cfe3"
]

let package = Package(
    name: "media_kit_libs_macos_audio",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "media-kit-libs-macos-audio", targets: ["media_kit_libs_macos_audio"] + libmpvTargets),
        .library(name: "Mpv", targets: ["Mpv"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: libmpvTargets.map { framework in
        .binaryTarget(
            name: framework,
            url: "\(libmpvArtifactBase)_\(framework).zip",
            checksum: libmpvChecksums[framework]!
        )
    } + [
        .target(
            name: "media_kit_libs_macos_audio",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ] + libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
