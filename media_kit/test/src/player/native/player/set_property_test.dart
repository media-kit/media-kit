import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit/src/player/native/core/initializer.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MediaKit.ensureInitialized();
    NativePlayer.test = true;
  });

  for (final asynchronous in [true, false]) {
    group('setProperty async=$asynchronous', () {
      late Player player;
      late NativePlayer native;

      setUp(() async {
        player = Player(
          configuration: PlayerConfiguration(async: asynchronous),
        );
        native = player.platform! as NativePlayer;
        await native.waitForPlayerInitialization;
      });

      tearDown(() => player.dispose());

      test('awaited writes complete in order', () async {
        for (final volume in [25, 65, 10]) {
          await native.setProperty('volume', '$volume');
          expect(double.parse(await native.getProperty('volume')), volume);
        }
      });

      test('unknown properties report an error and do not block later writes',
          () async {
        final error = player.stream.log.firstWhere(
          (log) =>
              log.prefix == 'media_kit' &&
              log.level == 'error' &&
              log.text.contains('_setProperty(media-kit-unknown-property,'),
        );
        await native.setProperty('media-kit-unknown-property', 'yes');
        expect((await error.timeout(const Duration(seconds: 2))).text,
            contains('property not found'));
        await native.setProperty('volume', '35');
        expect(double.parse(await native.getProperty('volume')), 35);
      });

      test('invalid values report an error and leave the property unchanged',
          () async {
        await native.setProperty('volume', '40');
        final error = player.stream.log.firstWhere(
          (log) =>
              log.prefix == 'media_kit' &&
              log.level == 'error' &&
              log.text.contains('_setProperty(volume,'),
        );
        await native.setProperty('volume', 'not-a-number');
        await error.timeout(const Duration(seconds: 2));
        expect(double.parse(await native.getProperty('volume')), 40);
      });

      test('dispose rejects subsequent writes', () async {
        await player.dispose();
        await expectLater(
          native.setProperty('volume', '20'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('completion follows the configured reply mode', () async {
        // Without event delivery an asynchronous write must remain pending;
        // the synchronous configuration must still complete immediately.
        Initializer(native.mpv).dispose(native.ctx);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        var completed = false;
        Object? failure;
        final write = native.setProperty('volume', '30').then<void>(
          (_) {
            completed = true;
          },
          onError: (Object error) {
            failure = error;
            completed = true;
          },
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(completed, !asynchronous);
        await player.dispose().timeout(const Duration(seconds: 3));
        await write.timeout(const Duration(seconds: 3));
        expect(completed, isTrue);
        expect(failure, asynchronous ? isA<StateError>() : isNull);
      });
    });
  }
}
