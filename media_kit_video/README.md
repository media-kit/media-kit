# [package:media_kit_video](https://github.com/media-kit/media-kit)

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/media-kit/media-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/media-kit/media-kit/actions/workflows/ci.yml)

Native implementation for video playback in [package:media_kit](https://pub.dev/packages/media_kit).

## Native rendering-mode integration (Darwin)

The registered plugin publishes its `MediaKitVideoPlugin` instance through
Flutter's plugin registry. Native integrations can use this typed API without
intercepting the plugin's method channel or replaying its create/dispose messages.
Call these APIs and consume their callbacks on the Flutter platform/main thread.
When the optional native video libraries are absent, the stub publishes the same
API but reports `.failed` for transitions and returns no software-rendering handles.

```swift
import media_kit_video

let video = registry.valuePublished(byPlugin: "MediaKitVideoPlugin")
    as? MediaKitVideoPlugin

// Also keep outputs created by playlist/episode changes on the software path.
video?.setSoftwareRenderingForNewOutputs(true)

// Suspend this player's video track (vid=no) and confirm it before calling.
video?.setSoftwareRendering(handle: handle, enabled: true) { result in
    switch result {
    case .changed:
        // Replacement context exists and its new texture ID has been emitted.
        // Restore the saved vid after the Dart texture listener observes it.
        break
    case .unchanged:
        // Already in this mode, or hardware rendering was disabled originally.
        // Restore vid directly; no new texture ID will be emitted.
        break
    case .notReady:
        // Another initialization/transition is pending. Restore vid directly,
        // then retry after that output becomes ready; do not wait for a new ID
        // inside this request.
        break
    case .failed:
        // Restore vid directly as well. Do not leave the player disabled.
        break
    }
}
```

`enabled: false` restores the original output configuration, including the user's
hardware-rendering preference. It does not force GPU rendering for an originally
software output. The temporary override does not replace the mpv player or alter
its media, audio, playback position, decoder configuration, or shader options.
Software rendering does not apply GPU shader effects. A compatible copy-back
hardware decoder is needed when switching from GPU to software rendering; this
API deliberately does not change the player's decoder settings.

The caller owns the video-track suspension/restoration transaction and must
serialize it per player, retain the exact player instance, and restore `vid` in
all completion paths. The plugin owns output configuration, the latest dimensions,
context/texture replacement, and disposal. Completion waits for initialization
and texture registration, not the first frame: a frame cannot be produced until
`vid` is restored. Overlapping initialization/transitions return `.notReady`;
unknown/disposed handles and outputs whose recovery failed return `.failed`.
Only `.notReady` permits a readiness-triggered retry. Retrying `.failed` on every
texture registration would loop when hardware is unavailable or the simulator
falls back to software. A target initialization failure attempts to recreate the
previous renderer before reporting `.failed`. If that recovery also fails, the
output is not reported as ready; the integration must surface a playback failure
or recreate the player. Disposal remains available and drains all resources.

On iOS, request GPU restoration only when the application is active. The plugin
also checks application state before replacing an output, and guards the state
check plus GPU-context initialization in one platform-thread turn. Existing GPU
outputs gate resize/render work when the application resigns active; the lifecycle
callback waits for an in-flight GL section, and activation requests a fresh frame.
An output initially created while inactive also falls back to software and is
listed in `softwareRenderingHandles`; the integration must restore it on
activation using the same video-track suspension transaction.
Property reads and platform notifications stay outside that render lock. If the
app backgrounds during restoration, it keeps/recreates a
software output and reports `.failed`; the handle remains in
`softwareRenderingHandles` so restoration can be retried on the next activation.
Do not interpret `.failed` as proof that the old texture ID still exists.

When leaving background playback, set the new-output default back to `false`,
then iterate `softwareRenderingHandles` and run the same suspend / set / restore
transaction with `enabled: false`. Changing the default alone does not replace
existing outputs. If a handle is still being initialized, retry after its normal
video-controller readiness signal. While background restoration is pending,
keep the new-output default enabled so later playlist/episode outputs stay safe.

Run the deterministic native lifecycle tests with:

```sh
media_kit_video/tool/rendering_mode_test/run.sh
```

These compile the real manager against controlled output doubles and cover
readiness, resize races, duplicate requests, initialization failures/rollback,
disposal, handle reuse, and backgrounding during GPU restoration. Additional
checks use the real output worker to verify delayed context readiness, safe
queued disposal, initialization failure, cancellation resource release, and the
concurrent background render gate. Run these tests on macOS; they do not
replace device validation: the iOS simulator forces software rendering, so a
physical device is required to validate GPU -> software -> GPU, PiP background
frames, and shader restoration.

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
