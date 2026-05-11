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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.0/libmpv-xcframeworks_v0.7.0_ios-universal-audio-default"
let libmpvChecksums = [
    "Avcodec": "0603092e376ff396bcfb5e93e6af61b047b0f9b50efcf8d53f93f2b347c1d537",
    "Avfilter": "9f78b4b9ae03784183b4aeb2c916af7609d3969b0e6845a6a4a0e571982f78d3",
    "Avformat": "b2485d949649574c7b98a9fba32e51c26b6aaff3a9cae21c7c30a5e5cd3c4379",
    "Avutil": "0c29965740fa1a110a47a8839492de93e305bbba0ccb6602be61f9b396b60d02",
    "Mbedcrypto": "ae80a9915a93589aaab373be7428e92e577749a724bff7054550449f3aee7083",
    "Mbedtls": "60a7135f9c93d90aa56232255a997e6f699d7d7df9ddab32e97470700216241b",
    "Mbedx509": "3eb4221a54c2652b85351a61b6b7f6f5a613dac743120655174c21892faa8eae",
    "Mpv": "2d683792d1461307c7a79e57df987dae5d640310f788de595ce3e16f5181a0ad",
    "Swresample": "d63bc716105d409b61fd671fb824a1cf8bc3f927d699d75a90e5571af1349f3e",
    "Swscale": "368135287a59ae417b9ab1607b046ba3e740bdb4b814fe328e83b6d0fee356eb"
]

let package = Package(
    name: "media_kit_libs_ios_audio",
    platforms: [
        .iOS("9.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-audio", targets: ["media_kit_libs_ios_audio"] + libmpvTargets)
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
            name: "media_kit_libs_ios_audio",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
