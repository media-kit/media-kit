## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit_video: ^0.0.4
```

## Usage

```dart
import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';                        /// Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';            /// Provides [VideoController] & [Video] etc.

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  /// Create a [Player].
  final Player player = Player();
  /// Store reference to the [VideoController].
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      /// Create a [VideoController] to show video output of the [Player].
      controller = await VideoController.create(player);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      /// Release allocated resources back to the system.
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Use [Video] widget to display the output.
    return Video(
      /// Pass the [controller].
      controller: controller,
    );
  }
}
```
