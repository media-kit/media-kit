import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libmpv/generated/bindings.dart';

import 'package:libmpv/libmpv.dart';

Future<void> main(List<String> args) async {
  var handle = await create(
    '/usr/lib/x86_64-linux-gnu/libmpv.so',
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
  mpv.mpv_command(
    handle,
    [
      'loadfile',
      args.first,
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
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(join('').length);
    for (int index = 0; index < length; index++) {
      arr[index] = ptr[index];
    }
    return arr;
  }
}
