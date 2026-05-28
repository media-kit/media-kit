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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.0/libmpv-xcframeworks_v0.7.0_macos-universal-video-default"
let libmpvChecksums = [
    "Ass": "5766993f7b6626a1943a4572345091b8ead509889fa656b2b9ca1a4ee50036b8",
    "Avcodec": "f642641b41bb3227f299b929ebbd253c834495f8aad6672d42161b7f3f1eea9d",
    "Avfilter": "151a6c1edf46cb10a7a4ed0912eabb00309f95bd0e142a867a2e742a423d2e8c",
    "Avformat": "98982b284b770c55976a95a2ce5e3c0d3b4db384b698977dcd3fb432544f49d4",
    "Avutil": "404f58a9ccefa2505ffdc7125839088dabf05dfad59982c44ef260f7cfbfd752",
    "Dav1d": "c8ce0efc7fa01ac79f3932e74cb258a51b59d1fd42e8cca4100b42b5c5816ff0",
    "Freetype": "71c6290bcb6f2f5e58f0a7fb88d75e5df666c0c35f95a261e8886016bb828ad3",
    "Fribidi": "526476cd44edadeacf4995557a4fada4770e0cff596ba7f13878ccf61244faa7",
    "Harfbuzz": "09411c1cc7f8f954aeb4467c79d70b9a28a66189c717966835b5ea8b8cb1c24b",
    "Mbedcrypto": "4d1c8cac9a138f87a027d3693a4e79cefbe93e3a437fc120b12b3ccee7561a1f",
    "Mbedtls": "35487e0a17f77aeb90fbe0bda8287a6199e5785329a44236dd07146fcf8241f6",
    "Mbedx509": "6fbaf1af7ea11d261565b293fe622d746d3be415e56d8b3b73de40840ec1c501",
    "Mpv": "02b4eb1d5d43f458b626f1a4480a31130d7d8226df898079e02bd9828693296b",
    "Png16": "54cc05350a439a72f0b9d2515d832366a542cccf234c0def201c5b83b6a665e6",
    "Swresample": "227e182659babff202f41123b27c120efd9903bb32f8982bedb4e5b097b06397",
    "Swscale": "3dd30c36e5e9cd0386ea9e78629b2e0d0a43134e7104a11673e2d5ca2f18db67",
    "Uchardet": "3731cd02e84a4a5f8424ee10cde7dc3ce13ed2a12b9acc98b3ebf9b59ce37482",
    "Xml2": "641e2548c57ef035aab2fd04a8c9ee4f54664ed5a912b3002961d1d4422acfee"
]
let libmpvProductTargets: [String] = ["media_kit_libs_macos_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_macos_video",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        .library(name: "media-kit-libs-macos-video", targets: libmpvProductTargets),
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
            name: "media_kit_libs_macos_video",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
