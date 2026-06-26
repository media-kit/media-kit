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

let libmpvArtifactBase = "https://github.com/media-kit/libmpv-darwin-build/releases/download/v0.7.1/libmpv-xcframeworks_v0.7.1_macos-universal-video-default"
let libmpvChecksums = [
    "Ass": "e502fb61bea153a185a8cc0d26d0f1f5c976ddf4a921d1dc96def9356f54b0d6",
    "Avcodec": "7f245a3943a45d726e5cbf232168f597321ce1f9064806b49ab1c325f0ad6487",
    "Avfilter": "215760cc4ad04f182fc8409d71f1cff1df63bc031831d449f5865b198b2dc8be",
    "Avformat": "de5e2592c84c42b0c9915a65f7ef580953785dd3a0baca814dae40fb2526545b",
    "Avutil": "b4584a8e6162c29c7b9dc32f4ece1c4013cbf3abd37960d696c17213e9dcc3c8",
    "Dav1d": "0fdcd4f14d8f9609db9afa9b01b754ae1d17cbdb31094f65dc5846d14f69aeec",
    "Freetype": "901266bcc8ddff143c4db270127fb122472ed9f5b5ea6513f268084bdbb166d1",
    "Fribidi": "a58af6b8554fd25839600c49d44504485959b36a1b32f446e786917336737dbe",
    "Harfbuzz": "1975db6e0752026155260f83bf6045d653500cd4c6a4f9cd513a5a3420e2486a",
    "Mbedcrypto": "b759eccdba9ae393a510ae47c3baeddd75ea59203e909fab52e7404206d71257",
    "Mbedtls": "42873e6a2b4279101aae81351dbaef4ee25799d2bada6b096bdd02fe4c99dab5",
    "Mbedx509": "7f0d7abf3d23a2e021c4ab6ea3b44f41f3993bdd195ec3645e5dd03e2d2b0d94",
    "Mpv": "cd123780e3dbbee383789057268efdb01be0517cbee59129010e4656ba39013a",
    "Png16": "78af66de16501607261343480a1b67bbc8ab3efb359ffba5506a8a8e55370cc5",
    "Swresample": "0a9ab8712228c82551e0c79ee4980954902e975c5949ad13a40de15426998dae",
    "Swscale": "85e9e3418ec34037ba88bc6ebf630fc1fb6e93124710ba66dd37f91b51084f78",
    "Uchardet": "00913528f1199a6440431f3402dbc8184ae98179bcc94f773b70327665b12c26",
    "Xml2": "fc2bac44396429c3efb098da7994503b3a8b1fdc766f0aab73a29ce004488c54"
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
