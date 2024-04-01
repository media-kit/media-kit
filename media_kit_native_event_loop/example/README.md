## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit_native_event_loop:
    git:
      url: https://github.com/isaacy13/media-kit-themedeck
      ref: main
      path: media_kit_native_event_loop
```

This will automatically allow using higher number of concurrent instances.

A workaround for [dart-lang/sdk#51254](https://github.com/dart-lang/sdk/issues/51254) & [dart-lang/sdk#51261](https://github.com/dart-lang/sdk/issues/51261).
