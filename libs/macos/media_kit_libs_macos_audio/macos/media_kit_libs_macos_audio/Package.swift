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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.1/libmpv-xcframeworks_v0.7.1_macos-universal-audio-full"
let libmpvChecksums = [
    "Avcodec": "cab7c613868a74a2cc71907e3947bb8e0c12bb450776eb013162d903fc7d2480",
    "Avfilter": "177da240e9705fffd3d1128baf8860c72fc1191449e089e3adfb5ed21b1a2319",
    "Avformat": "a8d3991c3cacfe4eae3b34a0b3392ca95f3cb160262b2513e22ddc937f61e815",
    "Avutil": "49d5f214c1b58d1b967e0aad9c228d05a324ba691f002c1a43d9b4062a6aa2c7",
    "Mbedcrypto": "46cc345d9dae293ccf35c32a25e95c9a52a8122e04085d7ec3d33221cd64323c",
    "Mbedtls": "d453209e83882005b2cf0bfc8ba9f62aa19211fa241d3d2d3602a2ae3480b15b",
    "Mbedx509": "af58d627b016d21cf87b24cd372c570e1bf391322219714b8a4d48cbbf58cf73",
    "Mpv": "c50102fb91b3e628e7a28b506d0054334fc2a3f543a58350c1f1b32aeca4988e",
    "Swresample": "ccd8e0889c8d2a4684cd0d6fac0e8af117bcaf024919b624d6b94c3943b07426",
    "Swscale": "34b22141b77ef040a7790aa103ae25c22320c23e4f51e7b3c0428e737147a502"
]

let package = Package(
    name: "media_kit_libs_macos_audio",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        .library(name: "media-kit-libs-macos-audio", targets: ["media_kit_libs_macos_audio"] + libmpvTargets),
        .library(name: "Mpv", targets: ["Mpv"])
    ],
    dependencies: [],
    targets: libmpvTargets.map { framework in
        .binaryTarget(
            name: framework,
            url: "\(libmpvArtifactBase)_\(framework).zip",
            checksum: libmpvChecksums[framework]!
        )
    } + [
        .target(
            name: "media_kit_libs_macos_audio",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
