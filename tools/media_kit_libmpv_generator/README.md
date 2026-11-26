# libmpv bindings

The sole input is the unmodified official `include/mpv/client.h` from
[mpv v0.42.0](https://github.com/mpv-player/mpv/tree/v0.42.0) (Client API 2.6).
The generator uses **ffigen 23.0.0**, `DynamicLibraryBindings`, and Dart enums.
`MPV(dynamicLibrary)` retains lazy symbol lookup; enum `.value` holds the C
integer (not `.index`). Public event observation methods still accept integers
and convert them with `mpv_event_id.fromValue`.

The header is downloaded locally and ignored by Git. From the repository root:

```sh
mkdir -p tools/media_kit_libmpv_generator/headers/mpv
curl --fail --location https://raw.githubusercontent.com/mpv-player/mpv/v0.42.0/include/mpv/client.h \
  --output tools/media_kit_libmpv_generator/headers/mpv/client.h
```

SHA-256: `3da9b8c61c3fb4e2d76bd248cebf72f3ee830331411b71a76adbd5e05660cc50`.
No render or stream headers are needed by these Dart bindings.

The generator shares dependency resolution with the root Pub workspace.
Install a C compiler and libclang (Xcode on macOS, LLVM on Linux/Windows),
then run from the repository root:

```sh
dart pub get
cd tools/media_kit_libmpv_generator
dart run ffigen.dart
dart test
```

Output goes directly to `media_kit/lib/generated/libmpv/bindings.dart`; paths
are resolved relative to the script. ffigen's warning about the missing definition of
`mpv_handle` is expected: it is an opaque C handle.

## Compatibility

The minimum native version remains **libmpv 0.35.1 (Client API 2.0)**.
Every Client API function called from `lib/src` exists in 2.0. Clang AST
comparison of the official 0.35.1 and 0.42.0 headers found unchanged signatures
for common functions and unchanged struct fields. The tests compare all
exposed enum constants and 11 struct sizes with a host C compiler. mpv uses
ordinary C enums; builds with nonstandard enum packing are not supported.

`MPV` constructors must not resolve symbols. Generated `late final` fields
resolve and cache each symbol only on first use. Tests verify this using a
lookup callback that exposes only the API 2.0 version function. New functions
`mpv_del_property` (2.1) and `mpv_get_time_ns` (2.2) are generated but unused by
playback code. Future callers must check `mpv_client_api_version()` or symbol
availability before calling them on an older library.

Compared with the previous generated file, obsolete `mpv_detach_destroy`,
`mpv_suspend`, `mpv_resume`, `mpv_get_sub_api`, `mpv_sub_api`, and its OpenGL constant disappear,
as do the events removed in API 2.0: SCRIPT_INPUT_DISPATCH, PAUSE, UNPAUSE,
TRACKS_CHANGED, TRACK_SWITCHED, METADATA_UPDATE, CHAPTER_CHANGE.
The default `MPV_ENABLE_DEPRECATED=1` keeps IDLE, TICK and
`mpv_get_wakeup_pipe`. None is used by the main Dart code. API 2.0 also removed the obsolete opengl_cb API headers and functions. mpv 0.34.0 used Client API 1.109 and is not the supported
minimum. See the official
[Client API history](https://github.com/mpv-player/mpv/blob/v0.42.0/DOCS/client-api-changes.rst).

To repeat the ABI test against 0.35.1 (from this directory):

```sh
curl --fail --location https://raw.githubusercontent.com/mpv-player/mpv/v0.35.1/libmpv/client.h \
  --output /tmp/mpv-client-0.35.1.h
MPV_HEADER=/tmp/mpv-client-0.35.1.h dart test
```

These tests check lazy lookup and the host ABI, not real playback or every
platform ABI. Native runtime smoke tests with actual **0.35.1 and 0.42.0**
builds remain necessary; neither version was available during this update.
Native libraries, playback behavior, and the public media-kit API are unchanged.
