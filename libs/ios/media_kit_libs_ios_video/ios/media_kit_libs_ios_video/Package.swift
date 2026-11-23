// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let libmpvTargets = [
    "Ass",
    "Avcodec",
    "Avfilter",
    "Avformat",
    "Avutil",
    "Dav1d",
    "Freetype",
    "Fribidi",
    "Harfbuzz",
    "Mbedcrypto",
    "Mbedtls",
    "Mbedx509",
    "Mpv",
    "Png16",
    "Swresample",
    "Swscale",
    "Uchardet",
    "Xml2"
]

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.3/libmpv-xcframeworks_v0.7.3_ios-universal-video-default"
let libmpvChecksums = [
    "Ass": "efe8a9ab5cb9ef652aa0f16aedda928422863b020526f7c88c9af851e35bdd15",
    "Avcodec": "e8f097a6a6d20f73dd3cd4ca885bf0949e2cba950f9bf3233132664dce7bb874",
    "Avfilter": "e1e456db5cd379caa2ec8cc3f949dd0102721ce740a81728e5c2fab2f8046001",
    "Avformat": "0aec25db2ad4be4e16ff8cd5c254b6e328ad62e423971da4295ed77b3484f25a",
    "Avutil": "51eebe9998b6b3e3b54bc953ffcab50c39d82d5fdb8be6498e8f66e0623c43d8",
    "Dav1d": "8a623e4d725b09afc5991487a2758917b8357ec010a3138492bd0965637927d2",
    "Freetype": "1345c7cea89e6bc4d77b7382ba413e71daa4f7e48b5b88f8910ab09277b536da",
    "Fribidi": "4a20dc886808937af75d4aa10a7550e4258d4f49f63f0644b293149fae0b4e83",
    "Harfbuzz": "8357126f22cc103df6da5b91153de2adc8dd3d931ac1110643821d262c94b1fb",
    "Mbedcrypto": "f64ce3b86d45ca4e98ae75e878d3470d85eb19e15ea608f2236842b4c4189bc3",
    "Mbedtls": "165c659021262b7c51ee753bf11c73038c7f37a93e7a849899377f62b2e9d554",
    "Mbedx509": "b9b90d15b1cc20730519b38ac08f89902c64511d06f4ebd94379923361dfb2b1",
    "Mpv": "3e9dfc1d91370b5dc40fba533cf71e65a184f90603f12795980cf7a094535bd2",
    "Png16": "acab34ff79d427fcbda1cbcb1fb8e953b385cdf8d0557948be6598814df47ba7",
    "Swresample": "b4d2dcdfead9775d6b1b6c195f8b7a9ec1950035803cd9e112ace2daab61f780",
    "Swscale": "959fe52c7e09a67b28126871438dc1b9f4a856be0a8911bc7a70cf69cfb9c4dc",
    "Uchardet": "31f3b7eeaf408588107832dcefd9bcb254df38ed9d3af434596016b598c2522f",
    "Xml2": "d2e9a5c54eb8662653d4772a38c15ce2cc2941377d3d41e59206c80f36fff67e"
]
let libmpvProductTargets: [String] = ["media_kit_libs_ios_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_ios_video",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-video", targets: libmpvProductTargets),
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
            name: "media_kit_libs_ios_video",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ] + libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
