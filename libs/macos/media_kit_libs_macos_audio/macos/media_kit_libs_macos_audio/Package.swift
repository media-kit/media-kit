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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.2/libmpv-xcframeworks_v0.7.2_macos-universal-audio-full"
let libmpvChecksums = [
    "Avcodec": "3019da15c5b7767d7dc4d70edc86de467cb74ca2cd3a8194db5049fa5dd9ba01",
    "Avfilter": "fcfcc281e003177e72d521b8a297ab7205e238bbeaa03309ed0fc1293a5e54bc",
    "Avformat": "cbce6959c1c3c05d44f7895bd0ead6e23d79cb207f76d007578e8bee5fe19208",
    "Avutil": "7fff02e8c7fe945cad51e9994364ea38e31d3085e3c9395fc1b56dd75fd4c1e0",
    "Mbedcrypto": "a9747876764cc95d7a222191bb04c9e89dca23d582664e4ada3cdb83c112ab37",
    "Mbedtls": "fad60234122c4e6c78d52b31a9790a33dbf124a7ba30174c7570dab13b390b77",
    "Mbedx509": "2246704fbaa1a1c13f357303016cc4c719e597a93380b091e46e977ec0134341",
    "Mpv": "14a370ac4f1c9e3da4809ad0e9c400aed65773daf8907325e98fd773294edb9d",
    "Swresample": "c862de2cd5975a87f86119845cbc6cb89db58bb8918f607d8f81dfbc4dd87caf",
    "Swscale": "4aa0ad799043458cfc07742b39146ecefda27516bf8af0b52de405abdaf2ddd0"
]

let package = Package(
    name: "media_kit_libs_macos_audio",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        .library(name: "media-kit-libs-macos-audio", targets: ["media_kit_libs_macos_audio"] + libmpvTargets),
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
