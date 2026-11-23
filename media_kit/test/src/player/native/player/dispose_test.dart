import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit/generated/libmpv/bindings.dart';
import 'package:media_kit/src/player/native/core/initializer.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    MediaKit.ensureInitialized();
    NativePlayer.test = true;
  });

  test('dispose cancels property and command replies with no event loop',
      () async {
    final player = Player();
    final native = player.platform! as NativePlayer;
    await native.waitForPlayerInitialization;
    // Simulate event delivery ending while libmpv still accepts requests.
    Initializer(native.mpv).dispose(native.ctx);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var finished = 0;
    Future<void> cancelled(Future<void> operation) async {
      await expectLater(operation, throwsStateError);
      finished++;
    }

    // The property request holds the player lock; dispose must cancel it before
    // trying to acquire that same lock. The command waits independently.
    final property = cancelled(player.setVolume(25));
    final command = cancelled(native.stop(synchronized: false));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(finished, 0);
    await player.dispose().timeout(const Duration(seconds: 3));
    await Future.wait([property, command]);
    expect(finished, 2);
    await player.dispose().timeout(const Duration(seconds: 3));
    await expectLater(player.setVolume(50), throwsA(isA<AssertionError>()));
  });

  test('dispose during initialization and repeat dispose finish once',
      () async {
    final player = Player();
    var released = 0;
    player.platform!.release.add(() async => released++);
    await Future.wait([player.dispose(), player.dispose()])
        .timeout(const Duration(seconds: 5));
    expect(released, 1);
  });

  test('cleanup callbacks may remove themselves', () async {
    final player =
        Player(configuration: const PlayerConfiguration(async: false));
    var released = 0;
    late Future<void> Function() first;
    first = () async {
      player.platform!.release.remove(first);
      released++;
    };
    player.platform!.release.add(first);
    player.platform!.release.add(() async => released++);
    await player.dispose().timeout(const Duration(seconds: 5));
    expect(released, 2);
  });

  test('mpv shutdown rejects requests and permits cleanup', () async {
    final player = Player();
    final native = player.platform! as NativePlayer;
    final shutdown = Completer<void>();
    await native.observeEvent(mpv_event_id.MPV_EVENT_SHUTDOWN.value, (_) async {
      shutdown.complete();
    });
    await native.command(['quit']);
    await shutdown.future.timeout(const Duration(seconds: 3));
    await expectLater(player.setVolume(20), throwsStateError);
    await player.dispose().timeout(const Duration(seconds: 3));
  });
}
