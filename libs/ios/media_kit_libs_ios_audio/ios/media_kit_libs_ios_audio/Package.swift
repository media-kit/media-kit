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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.3/libmpv-xcframeworks_v0.7.3_ios-universal-audio-default"
let libmpvChecksums = [
    "Avcodec": "bdfc178c242e3802cc863313365698323d30cc0de2a730bc7f390abd06f49adf",
    "Avfilter": "6e307b64987189541058313f757d28e07e7566286c668ed7d7c0f3bc18b1e169",
    "Avformat": "150aad0108eb6d8c149add47d7d2f4968249862fae710c2b95568310c5329e14",
    "Avutil": "2a1bfa4b7fcaf4eab2d180e3df3d203fcc3d8ca604316ddac11272c5d8c3dd08",
    "Mbedcrypto": "7bb424ce75c5f9d9fd11d43c29c5f9bad496c0f43d479eeb36f0e068317a872e",
    "Mbedtls": "fd016ecb5677ffa6fb5848629263e10ecfd04c18a929064c1fd116564c811009",
    "Mbedx509": "ecf52e1e9b5d9a40084a19c0611be8f0c1247b6b724a276fb1a1e0b4c4d04a8f",
    "Mpv": "9c3286e25bc59c4bc9370586dacf0822209e8ffee686b81d97e26d183417f921",
    "Swresample": "0e0b97692dd62d5ed8ab9e0f9d6ba33ab218d4f6f5a31486acaf0be0c2fc0149",
    "Swscale": "1494325eac801e95e92f0966203c42df07759ed9fd4ec2088283e50375ea3ffe"
]

let package = Package(
    name: "media_kit_libs_ios_audio",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-audio", targets: ["media_kit_libs_ios_audio"] + libmpvTargets),
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
            name: "media_kit_libs_ios_audio",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ] + libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
