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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.1/libmpv-xcframeworks_v0.7.1_ios-universal-video-default"
let libmpvChecksums = [
    "Ass": "bd8b0d6a2379134cd0bc818b85b6793315d52c47241cf2ca4f150d338e826a8b",
    "Avcodec": "ff97faa8c93bd880cd46ba8ac4bc8cb544a5239b28c5e3ccb38da17e0405762e",
    "Avfilter": "e97501e37efe7ad5d5ebe2be7096c3e823a3f4a196e265730934967b0a5ff944",
    "Avformat": "bfe385053f61cfa5b172806a1d05ca265d86d98829fa5f81c50d53cd5ffd5754",
    "Avutil": "7689b11bf4b478cea3a263da48dd91e722760198c1ecea754abf52836066ab5d",
    "Dav1d": "f83d4800e1c35d9e3c859f19e423f78ee7d6264685c2b891eafc2be1cb95d943",
    "Freetype": "5fcea16220be9ae6b093c462bf776cf0461edb96597ea9b40708f1c632044373",
    "Fribidi": "4e15ff832096e94dc22041dea007b6428cb5521907c3f1eddc7dbdc762db6382",
    "Harfbuzz": "7b84efb86831907634a1d2fffb1efaa594b6ed8499ce0f3d883e90ab47b33861",
    "Mbedcrypto": "9466d85c2d35ab13b9f660cd7c561787c1946c59f1fa9fd9e1d65d890958109a",
    "Mbedtls": "29f13ecf763942c7a3e408d5572ca1a3b4b2b11555fb5e6bb5bc9769449c1d42",
    "Mbedx509": "f46d2ab871b33f0729f5e5a6de45f05f80c78041e968a64e0613617d6c5ed199",
    "Mpv": "34de6fa812176f8f082582f2b2a6a3b7b924e25e3b9ba2d8e28e28c712face98",
    "Png16": "aee667b09ee6d929c627fd0a59b80b98eeb64ea8ab289680c51b9c2b8ef2058a",
    "Swresample": "a042e60998df01ec6a566332e9f30093ff921b849593038af6bd24aaad0b2fbe",
    "Swscale": "6b56bbf3502c775dab4f640b5e23e64c48ddc9ed9b85d79a6e0dbc71e2dbd50f",
    "Uchardet": "f56fa7a917c25b91c8f7c0b0aed6047d6179ea858dd7854ece61810500d9a735",
    "Xml2": "3395cd19d5a65b7669674cf43512bb338bae6079c31a6767c4a6426fd5a02659"
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
