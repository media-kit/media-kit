import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'generated/bindings.dart';

extension on List<String> {
  Pointer<Pointer<Utf8>> toNativeUtf8Array() {
    final listPointer = map((String string) => string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> pointerPointer =
        calloc.allocate(join('').length);
    for (int index = 0; index < length; index++) {
      pointerPointer[index] = listPointer[index];
    }
    return pointerPointer;
  }
}

var mpv = MPV(DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libmpv.so'));

void _create(SendPort port) {
  var ctx = mpv.mpv_create();
  mpv.mpv_initialize(ctx);
  port.send(ctx.address);
  while (true) {
    Pointer<mpv_event> event = mpv.mpv_wait_event(ctx, -1);
    port.send(event.address);
    if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
      break;
    }
  }
}

Future<void> main(List<String> arguments) async {
  var completer = Completer();
  var receiver = ReceivePort();
  late Pointer<mpv_handle> ctx;
  Isolate.spawn(
    _create,
    receiver.sendPort,
  );
  receiver.listen((address) {
    if (!completer.isCompleted) {
      ctx = Pointer.fromAddress(address);
      completer.complete();
    } else {
      Pointer<mpv_event> event = Pointer.fromAddress(address);
      print(mpv.mpv_event_name(event.ref.event_id).cast<Utf8>().toDartString());
    }
  });
  await completer.future;
  mpv.mpv_set_option_string(
    ctx,
    'input-default-bindings'.toNativeUtf8().cast(),
    'yes'.toNativeUtf8().cast(),
  );
  mpv.mpv_set_option_string(
    ctx,
    'input-vo-keyboard'.toNativeUtf8().cast(),
    'yes'.toNativeUtf8().cast(),
  );
  // mpv.mpv_observe_property(
  //   ctx,
  //   0,
  //   'time-pos'.toNativeUtf8().cast(),
  //   mpv_format.MPV_FORMAT_DOUBLE,
  // );
  mpv.mpv_command(
    ctx,
    [
      'loadfile',
      arguments.first,
    ].toNativeUtf8Array().cast(),
  );
}
