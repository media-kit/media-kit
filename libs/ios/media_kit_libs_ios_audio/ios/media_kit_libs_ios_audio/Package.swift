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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.1/libmpv-xcframeworks_v0.7.1_ios-universal-audio-default"
let libmpvChecksums = [
    "Avcodec": "1d291f9eeb46dadefc6091d1b1dadb5153b68bf8b282a1b84048373fc3772c6c",
    "Avfilter": "ffd589bd6fa582c3175d55348853e8e4d0d6a84a241a6583bf8e3ad253fd559c",
    "Avformat": "eb92be28931d4dee9e90bbb20a1f042bc907cecea115037046ba2842e834d1e0",
    "Avutil": "9d4e8c257806697b45fd136b1e147d963c7d2e455b275e5f8b75c36162330b77",
    "Mbedcrypto": "a908046caf80a82ee92a6d2ab88866ca0359812f8b486ce234fb4930f356395e",
    "Mbedtls": "398393d0c0195136e90c0e58da251dadfd028ce34f9e8992b07872999a21bada",
    "Mbedx509": "4b2954d33815f84c2161abe0e07a7223eff866134ee99c6b1b544f3d5eeff623",
    "Mpv": "9342a778d318ea85f3ca8cf88a4c30c790ae6a1959d578ee4299a027ef87d760",
    "Swresample": "1f980ce844ce39143535a610dc17e3e5c2a38ce7cf263a2fe999b30d4a35ccf4",
    "Swscale": "5c0b494910033a503cb91b0eae15ae0c7f07e07cc912e140071e1425bfc8c228"
]

let package = Package(
    name: "media_kit_libs_ios_audio",
    platforms: [
        .iOS("9.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-audio", targets: ["media_kit_libs_ios_audio"] + libmpvTargets),
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
