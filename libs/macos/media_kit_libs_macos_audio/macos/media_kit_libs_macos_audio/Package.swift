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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.0/libmpv-xcframeworks_v0.7.0_macos-universal-audio-full"
let libmpvChecksums = [
    "Avcodec": "f6e069c6f5cafec22ef627581a060d1023ccf271d8c7b68f06bb0d88c950c004",
    "Avfilter": "ff96f16434b31a86abaf449899a00af513c250a5df1a10ca0a54edf44b56813e",
    "Avformat": "280f460238ba21a14499a597c0acf3136d91ef76695fbb92baa43cfae77e28a2",
    "Avutil": "e1f12d87fdb75cf171ee194732a982a28dd35629ffda19918df7f64a32a8ef33",
    "Mbedcrypto": "4d1c8cac9a138f87a027d3693a4e79cefbe93e3a437fc120b12b3ccee7561a1f",
    "Mbedtls": "35487e0a17f77aeb90fbe0bda8287a6199e5785329a44236dd07146fcf8241f6",
    "Mbedx509": "6fbaf1af7ea11d261565b293fe622d746d3be415e56d8b3b73de40840ec1c501",
    "Mpv": "38ba4f85bc035099497ebc95a068f20cd462162dae5b431f7fe64004041474c6",
    "Swresample": "86d9f31bc2ca354e45fcfdaf1b8fdd388b3d47d867d6789c688f2f61fd9552eb",
    "Swscale": "c0ef85b08ead86e0f968cfbd77b1d6914dc341ecd1e3374870411be6ebbd16f0"
]

let package = Package(
    name: "media_kit_libs_macos_audio",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        .library(name: "media-kit-libs-macos-audio", targets: ["media_kit_libs_macos_audio"] + libmpvTargets)
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
            name: "media_kit_libs_macos_audio",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
