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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.2/libmpv-xcframeworks_v0.7.2_macos-universal-video-default"
let libmpvChecksums = [
    "Ass": "a2ee62e663698533443b160dce1f1a9e5806df5cbb80d632abdafca5fa857cff",
    "Avcodec": "5249e4ca10b8176ab7f3b353300a7cdedee0beec85a301ac7171db2cae49890a",
    "Avfilter": "58ad9ea3ec51013e9b051a5836d992d9c18c7a832568b705be37d9a2085c234f",
    "Avformat": "302601edb397ac0845a9ded886615ab8f9689807b0d2987056e1d8a20d590370",
    "Avutil": "1a3e9e3952807793477b491a2ea5832a67a316021fb2be92fc87fb5890bd4fbb",
    "Dav1d": "a16c707091b643a2356d4393e9310ec9a4782076676442a7c3edb7debd6a2eea",
    "Freetype": "55250debc9ebdb68529630ba00f9e5c19875ee6dd75f1c8556d0f8ef3ff82857",
    "Fribidi": "46a684eb89ebc69712b7e623aedb151745a799f4e4dd81306c3b9fe1502cdc1d",
    "Harfbuzz": "f91b9609e1e4383678d4a1cbb6e376d19e11bbf81410bc20b1d7f942a1147a33",
    "Mbedcrypto": "4620bae7d478aed05c33ea43c0baa040691a97fff76ed6a2919a5324d2ff09a2",
    "Mbedtls": "e51e42c65b914433c2822677cecc5289adbabd365bc0b6df17bd3bbe17ab113a",
    "Mbedx509": "fb76ec7dcd8c145a6f8140ee801dcd93492b5e5b0555233154cf0a2f220b09dd",
    "Mpv": "5884589503b2dc7380666cc2bdc370be79a2e67cafe1159941901ef4e099ba90",
    "Png16": "5606ce2919f3fa1e8b0190c4ed62322ae5555e66eea2716d91c53fd526c79c96",
    "Swresample": "62f3ac54a07b370ac5146d676a5a75321908b19ece546a4e3b1ed2c3f3213166",
    "Swscale": "26201930bfb7bfcd02eea2ad78a3d6bcf593e85bb1a894cf3925316800f3c54a",
    "Uchardet": "14beb98e593abdda240c057f0098eefd2231849a20b084145e00a3c8894e0b86",
    "Xml2": "af478e048164312c9f53ec8b5e870679e52290b6ebb3ff472c31367db0b0e2ce"
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
