import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/src/video_controller/native_video_controller/real.dart';

const channel = MethodChannel('com.alexmercerind/media_kit_video');
const configuration = VideoControllerConfiguration();

Future<void> resize(int handle, {int id = 0, int size = 0}) async {
  final done = Completer<void>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    channel.name,
    const StandardMethodCodec()
        .encodeMethodCall(MethodCall('VideoOutput.Resize', {
      'handle': handle,
      'id': id,
      'rect': {'left': 0, 'top': 0, 'width': size, 'height': size},
    })),
    (_) => done.complete(),
  );
  await done.future;
}

void mock(Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, handler);
}

class FailingPropertyPlayer extends NativePlayer {
  FailingPropertyPlayer() : super(configuration: const PlayerConfiguration());
  bool fail = true;

  void emitVideoParams(VideoParams params) => videoParamsController.add(params);

  @override
  Future<void> setProperty(String property, String value,
      {bool waitForInitialization = true}) async {
    if (fail) throw StateError('injected property failure');
    await super.setProperty(property, value,
        waitForInitialization: waitForInitialization);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    MediaKit.ensureInitialized();
    NativePlayer.test = true;
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('property failure releases controller and allows retry', () async {
    final native = FailingPropertyPlayer();
    final player = Player(platformPlayer: native);
    final handle = await player.handle;
    var creates = 0;
    mock((call) async {
      if (call.method.endsWith('.Create')) {
        creates++;
        await resize(handle, size: 10);
      }
      return null;
    });
    await expectLater(
        NativeVideoController.create(player, configuration), throwsStateError);
    expect(native.release, isEmpty);
    expect(creates, 0);
    native.fail = false;
    final controller =
        await NativeVideoController.create(player, configuration);
    expect(controller.id.value, 0);
    expect(creates, 1);
    await player.dispose();
    expect(native.release, isEmpty);
  });

  test('native Create failure cleans up and retry succeeds', () async {
    final player = Player();
    final handle = await player.handle;
    var creates = 0;
    var disposes = 0;
    mock((call) async {
      if (call.method.endsWith('.Create')) {
        if (++creates == 1) throw PlatformException(code: 'injected');
        await resize(handle, size: 10);
      } else if (call.method.endsWith('.Dispose')) {
        disposes++;
      }
      return null;
    });
    await expectLater(NativeVideoController.create(player, configuration),
        throwsA(isA<PlatformException>()));
    expect(player.platform!.release, isEmpty);
    final controllers = await Future.wait([
      NativeVideoController.create(player, configuration),
      NativeVideoController.create(player, configuration),
    ]);
    expect(identical(controllers[0], controllers[1]), isTrue);
    expect(creates, 2);
    await player.dispose();
    expect(disposes, 2);
    // Late platform callbacks must not touch disposed ValueNotifiers.
    await resize(handle, id: 12, size: 20);
  });

  for (final delayedReply in [false, true]) {
    test('dispose cancels creation (delayed reply: $delayedReply)', () async {
      final player = Player();
      final handle = await player.handle;
      final entered = Completer<void>();
      final reply = Completer<void>();
      var disposes = 0;
      mock((call) async {
        if (call.method.endsWith('.Create')) {
          entered.complete();
          if (delayedReply) await reply.future;
        } else if (call.method.endsWith('.Dispose')) {
          disposes++;
        }
        return null;
      });
      final creation = NativeVideoController.create(player, configuration);
      final cancelled = expectLater(creation, throwsStateError);
      await entered.future;
      await player.dispose().timeout(const Duration(seconds: 3));
      await cancelled;
      expect(disposes, 1);
      expect(player.platform!.release, isEmpty);
      reply.complete();
      await resize(handle, id: 99, size: 10);
    });
  }

  test('dispose completes first-frame wait when no frame arrived', () async {
    final player = Player();
    final handle = await player.handle;
    mock((call) async {
      if (call.method.endsWith('.Create')) await resize(handle);
      return null;
    });
    final controller =
        await NativeVideoController.create(player, configuration);
    final cancelled =
        expectLater(controller.waitUntilFirstFrameRendered, throwsStateError);
    await player.dispose();
    await cancelled;
  });

  test('dispose before Flutter first frame cancels wrapper initialization',
      () async {
    final player = Player();
    final controller = VideoController(player);
    final cancelled = expectLater(controller.platform.future, throwsStateError);
    await player.dispose().timeout(const Duration(seconds: 3));
    await cancelled;
    expect(player.platform!.videoControllerCompleter.isCompleted, isTrue);
    expect(controller.notifier.value, isNull);
  });

  test('wrapper removes listeners and ignores late resize', () async {
    final player = Player();
    final handle = await player.handle;
    mock((call) async {
      if (call.method.endsWith('.Create')) await resize(handle, size: 10);
      return null;
    });
    final controller = VideoController(player);
    final binding = TestWidgetsFlutterBinding.instance;
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
    await controller.platform.future.timeout(const Duration(seconds: 3));
    await player.platform!.videoControllerCompleter.future;
    expect(controller.id.value, 0);
    await resize(handle, id: 1, size: 20);
    expect(controller.id.value, 1);
    await player.dispose();
    await resize(handle, id: 2, size: 30);
    expect(controller.id.value, 1);
  });

  test('automatic resize failure can retry and subscription stops on dispose',
      () async {
    final native = FailingPropertyPlayer()..fail = false;
    final player = Player(platformPlayer: native);
    final handle = await player.handle;
    var attempts = 0;
    final failed = Completer<void>();
    final retried = Completer<void>();
    mock((call) async {
      if (call.method.endsWith('.Create')) await resize(handle, size: 10);
      if (call.method.endsWith('.SetSize')) {
        if (++attempts == 1) {
          failed.complete();
          throw PlatformException(code: 'resize-failed');
        }
        retried.complete();
      }
      return null;
    });
    final controller = await NativeVideoController.create(player, configuration)
        as NativeVideoController;
    const params = VideoParams(dw: 80, dh: 60, rotate: 0);
    native.emitVideoParams(params);
    await failed.future;
    await Future<void>.delayed(Duration.zero);
    expect(controller.videoParamsWidth, isNull);
    native.emitVideoParams(params);
    await retried.future;
    await Future<void>.delayed(Duration.zero);
    expect(controller.videoParamsWidth, 80);
    await player.dispose();
    expect(attempts, 2);
  });
}
