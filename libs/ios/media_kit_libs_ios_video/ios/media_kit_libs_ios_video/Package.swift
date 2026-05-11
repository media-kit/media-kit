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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.0/libmpv-xcframeworks_v0.7.0_ios-universal-video-default"
let libmpvChecksums = [
    "Ass": "0272e89d672183be70bf5fc2bebf1e89611589aea66a2487d45c0a4116db9d09",
    "Avcodec": "12ecfed8835d105b1a797a2fcd064338d16524ec1400cd85dd433dedbe92a43d",
    "Avfilter": "b9713a047521a23e0410ed535b4fe3229ba66c43a9a40a106dfc5d7c690bde62",
    "Avformat": "6df0fa376a35986edd638555f7783e60db6d72100adc96c33308f2a4d244c044",
    "Avutil": "937663c27c24b6f94508e55220220b5f3ae2d8768289ca4b817075f18942ba5e",
    "Dav1d": "8d43adc45b4951d0ba09fea1b9c4647b6e6fba738f1aa7be5cc05ab768993d2d",
    "Freetype": "3f993ee4fee11cdb5b3b272e4d40765ba772b06cbf7bbdb9ee7132f0555f9799",
    "Fribidi": "0902e6067d4b773bb91b6ed1aa4be48d55c21aa3df2b9c81e9070d5d9ccd2243",
    "Harfbuzz": "e7d369bf8aff9f41483cca32e441e56411feef8bec6c3fa2292f61fa79df060d",
    "Mbedcrypto": "bcedc3439dcbd87de9e2003c0988c4f45c66641d12062ba786f080469ead3400",
    "Mbedtls": "85e092445e32a64f31dab3d379a7d8a8d4cd798400dfb24ebbae5e4b2bd49711",
    "Mbedx509": "28175d5d55da490ceeabf513e90781bc1aedaf76f7085d1c58baa7a9be322225",
    "Mpv": "a180f30b1a3b201734d616c96463fbda21317a772633b5959cf255524996907c",
    "Png16": "97ea1d5c2b9d41c0e2bcb084b4e31456fe28d383b2cf89ad1df0d2c9d5717437",
    "Swresample": "89ebab241a9a1f908e60868ff597ae06971d7e1b26f3af25cb26e5c1840b97c6",
    "Swscale": "dc252e5acd7cd71eebdfe8e007ddf996d68d6bf02b69f9cfef963cab8b88e69d",
    "Uchardet": "1e9481c8a3b0546b753aab1348fbf1f80a746ef7cc3a47a90a7c7480dad95edf",
    "Xml2": "ccb8bd20971aa54faaa98e77faacb0e24c39cd2fb471edf7236a5d2a41d8287f"
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
