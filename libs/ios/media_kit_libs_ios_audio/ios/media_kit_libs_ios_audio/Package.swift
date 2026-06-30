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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.2/libmpv-xcframeworks_v0.7.2_ios-universal-audio-default"
let libmpvChecksums = [
    "Avcodec": "ad35bef8707e150a11c91d162c5e075ae9ad72bc551bbacdd3f9890e5b3b0f76",
    "Avfilter": "20d1e5f983726e7823078cc52c8885ec5acbd1768326598afc1fb45c7cd28632",
    "Avformat": "91e568e6a5877f76392c0ffe22e04e505c9e6e7f7bc1679a1139e78d85e0342e",
    "Avutil": "a1190aad0d6f22744a39ed5b42c670dd31b37ca54285e8d5d23550c2cee3cf43",
    "Mbedcrypto": "553856aa92dcaf36dd18465fb104840d078a6239330c5bfdf227ed372e95837b",
    "Mbedtls": "1454d2637ad631b376654ad16b698a5e79205052842b28e4bd525e003b75f3eb",
    "Mbedx509": "da78a7f46fd3ad573899ea319afe8139c90eeff93bd02374627899e2334e7d12",
    "Mpv": "a44012362e94eeb2487f7c262f4efa5401857334f675e47fe10a6daf8958a974",
    "Swresample": "35feada14f58805e659cd8949430da9becd13ea45768eb7eb2943a4e1b42524c",
    "Swscale": "cc83ceffaa7b4d5a060edbb4ff283dcf335c8c3023b197f12948895cab87d0ef"
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
