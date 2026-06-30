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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.2/libmpv-xcframeworks_v0.7.2_ios-universal-video-default"
let libmpvChecksums = [
    "Ass": "8a77837736a3606257f250c9b468afaeec97da5352352ca7a65729782affbc91",
    "Avcodec": "5c61c3505aad8c57b7a72f93e39c627b12ab334df817012a964e4aa07ef29775",
    "Avfilter": "34c5c17033174329672322fc1ebb378f5aaba3e9f2d240cd9cf801a648a45759",
    "Avformat": "f468b6fdbb9c9c3b5233eedd3178cc26c0ea823c03445aab013a5adb8227f094",
    "Avutil": "088bd468ded07da034628fa7b9692d61eb94be63a3a87be670263d0961fb89f1",
    "Dav1d": "a47af09f5382eb5e438cb550195845567bd5b213693d6304eeb3dcbac6c261a3",
    "Freetype": "1ac7bfec5ecdc089a33a83b2f51c5443bdfdd682d679f732313274549250ae59",
    "Fribidi": "e8f21d7b59511cc779bc695a662892401319ad90381290a42ee4b5a19bb3d626",
    "Harfbuzz": "986e71ffdfcf63ea5e46794e8e59a5125269e54414f8914cb0c287e03ed0534d",
    "Mbedcrypto": "bfc0fc42eb391f890a2ecff4c58b9f6beb294794bde74000341c1f5922666548",
    "Mbedtls": "15285eeb50d4f0dbaa55d1acf255eabd9be9fc010341706ac7a88a3262ce5579",
    "Mbedx509": "afcc5c50f7f4ce128d805e165691d5d44a2288e8d39a714055f16f2f3420ac67",
    "Mpv": "d2d563fdfdaf610dd7d50284f65cfb21743e3900f15da537a4c9dc7d6c6bb2a4",
    "Png16": "ca5dae5cfbf240a179a76c45c10f4fb89738d7f9ad68c2e7f5690d03625fc26e",
    "Swresample": "b498ccadbe69a782bd29e72981b5af759700276b77f03103a6d8d13d3eed6a23",
    "Swscale": "1cbd508b80dc66b64bdee045b9681bd0aeeee5f94d20ef9b8c9c0b3916de4188",
    "Uchardet": "4c68da0007e08a1cfa73e04c4eb8eb7533e13b4cc3ef7c768806dc69c9563081",
    "Xml2": "a16c5faef734c84048637f5bc6a3b58b79d696ce908f2e57b309e9b76023b7f1"
]
let libmpvProductTargets: [String] = ["media_kit_libs_ios_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_ios_video",
    platforms: [
        .iOS("9.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-video", targets: libmpvProductTargets),
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
            name: "media_kit_libs_ios_video",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
