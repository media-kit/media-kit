import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/core/initializer.dart';
import 'package:libmpv/generated/bindings.dart';
import 'package:libmpv/src/dynamic_library.dart' as dlib;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
        'Invalid usage.\nExample:\ndart raw.dart /home/path/to/a/media/file.mp4');
    return;
  }

  await dlib.MPV.initialize();

  var handle = await create(
    dlib.libmpv!,
    (event) async {
      if (event.ref.event_id == mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
        var prop = event.ref.data.cast<mpv_event_property>();
        if (prop.ref.name.cast<Utf8>().toDartString() == 'time-pos' &&
            prop.ref.format == mpv_format.MPV_FORMAT_DOUBLE) {
          print(
              '${prop.ref.name.cast<Utf8>().toDartString()}: ${prop.ref.data.cast<Double>().value}');
        }
      }
    },
  );
  mpv.mpv_set_option_string(
    handle,
    'vo'.toNativeUtf8().cast(),
    'null'.toNativeUtf8().cast(),
  );
  mpv.mpv_command(
    handle,
    [
      'loadfile',
      args.join(' '),
    ].toNativeUtf8Array().cast(),
  );
  mpv.mpv_observe_property(
    handle,
    0,
    'time-pos'.toNativeUtf8().cast(),
    mpv_format.MPV_FORMAT_DOUBLE,
  );
}

extension on List<String> {
  Pointer<Pointer<Utf8>> toNativeUtf8Array() {
    final ptr = map((String string) => string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> ptrPtr = calloc.allocate(join('').length);
    for (int index = 0; index < length; index++) {
      ptrPtr[index] = ptr[index];
    }
    return ptrPtr;
  }
}
