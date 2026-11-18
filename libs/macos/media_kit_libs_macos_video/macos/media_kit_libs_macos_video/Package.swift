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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.3/libmpv-xcframeworks_v0.7.3_macos-universal-video-default"
let libmpvChecksums = [
    "Ass": "b9205e08fae29705045da9492fc048689800b2568384598e1225448379dc3611",
    "Avcodec": "b0bb836c0de99f392f4c32b3c5dda67ff7b3a5e2958c34e5542aca365c0db14b",
    "Avfilter": "1842b77bda3dfdbe3db3133b0cd63488f247b9824c902ac236b36dfec3717b12",
    "Avformat": "099e4fda22cdd8c312048b8a50cbe7e86e2d09b3c1f8c30f7c5cc2c210bfa261",
    "Avutil": "e78a3e58ab409dace08edcca6a07fc3817cc203fe4de2057bf19a7df36ad0951",
    "Dav1d": "fb33d26dd7a00788a6cc1396bea90913b66f4cee21f8b6453f270003a26e68e4",
    "Freetype": "6c5e315bd3db608175698e55da812e9399a4f83f9271da85e39fe97f98061fd5",
    "Fribidi": "d908dcf4f305f9208fbcc9065b364bffc71702d4c8acb3092a61148f52906444",
    "Harfbuzz": "26cd02d73a4ba8f2321f97eec366e9b535099f807bf30635e2cd19d89916f8ae",
    "Mbedcrypto": "7bce20b522a9ba04d80e518c5666adad9b2690c722d670a1797aef6cbddf1b97",
    "Mbedtls": "f5184efc51f8e9d05cacaa6c4f84ee772ecb593c2f5e21fd5227f386f462bd41",
    "Mbedx509": "64df36246fe6438f994d2a0e7ef1b3f954291f553b043d9a5b73b7cf5cac2115",
    "Mpv": "6c772cf3725ddbfb5e63e9a0baeeeef83c2c9d1bbde573f61e1f2ef8a4a1fef2",
    "Png16": "680661f662846246294078a005fbd3cfc53df79a8a7ecdbc521e6974347a7c7a",
    "Swresample": "164fe56722fd78d89d3aa6e575096bedfab4585e1e161f8d5cec3128ff4cd14c",
    "Swscale": "f451f442e3344e1a7bbe375427028ccb714c789b370de05b0c6957dcf8fb872c",
    "Uchardet": "e0e37082ba56b79ef0c56ed2317402e49c730c46636f9aeac25a9adcc9db8518",
    "Xml2": "5dff9facc16c3d9572128c957f3404fff26e9cc92e4d438ec165da040af9f1b1"
]
let libmpvProductTargets: [String] = ["media_kit_libs_macos_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_macos_video",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "media-kit-libs-macos-video", targets: libmpvProductTargets),
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
            name: "media_kit_libs_macos_video",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ] + libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
