// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

const Duration _playDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // --------------------------------------------------
  VideoPlayerMediaKit.ensureInitialized(
    android: true,
    iOS: true,
    macOS: true,
    windows: true,
    linux: true,
  );
  // --------------------------------------------------

  late final VideoPlayerController controller;
  late final VideoPlayerController another;
  tearDown(() async {
    await controller.dispose();
    await another.dispose();
  });

  testWidgets(
    'can substitute one controller by another without crashing',
    (WidgetTester tester) async {
      // Use WebM for web to allow CI to use Chromium.
      const String videoAssetKey =
          kIsWeb ? 'assets/Butterfly-209.webm' : 'assets/Butterfly-209.mp4';

      controller = VideoPlayerController.asset(
        videoAssetKey,
      );
      another = VideoPlayerController.asset(
        videoAssetKey,
      );

      final Completer<void> started = Completer<void>();
      final Completer<void> ended = Completer<void>();

      another.addListener(() {
        if (another.value.isBuffering && !started.isCompleted) {
          started.complete();
        }
        if (started.isCompleted &&
            !another.value.isBuffering &&
            !ended.isCompleted) {
          ended.complete();
        }
      });

      await controller.initialize();
      await another.initialize();
      await controller.setVolume(0);
      await another.setVolume(0);

      await tester.pumpWidget(renderVideoWidget(controller));
      await controller.play();
      await tester.pumpAndSettle(_playDuration);
      await controller.pause();

      await controller.dispose();

      await tester.pumpWidget(renderVideoWidget(another));
      await another.play();
      await another.seekTo(const Duration(seconds: 5));
      await tester.pumpAndSettle(_playDuration);
      await another.pause();

      expect(
        another.value.position,
        (Duration position) => position > Duration.zero,
      );

      await expectLater(started.future, completes);
      await expectLater(ended.future, completes);
    },
  );
}

Widget renderVideoWidget(VideoPlayerController controller) {
  return Material(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    ),
  );
}
