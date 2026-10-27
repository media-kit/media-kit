import 'dart:ffi';
import 'dart:io';

import 'package:test/test.dart';

// This standalone tool package deliberately does not depend on media_kit.
// ignore: avoid_relative_lib_imports
import '../../../media_kit/lib/generated/libmpv/bindings.dart';

int _apiVersion() => 2 << 16;

void main() {
  test('constructors do not look up optional symbols; lookup is cached', () {
    // The process itself need not export any mpv symbols.
    MPV(DynamicLibrary.process());
    final lookedUp = <String>[];
    final version = Pointer.fromFunction<UnsignedLong Function()>(
      _apiVersion,
      0,
    );
    final mpv = MPV.fromLookup(<T extends NativeType>(String name) {
      lookedUp.add(name);
      if (name == 'mpv_client_api_version') return version.cast<T>();
      throw ArgumentError('Symbol unavailable in Client API 2.0: $name');
    });
    expect(lookedUp, isEmpty);
    expect(mpv.mpv_client_api_version(), 2 << 16);
    expect(mpv.mpv_client_api_version(), 2 << 16);
    expect(lookedUp, ['mpv_client_api_version']);
    expect(() => mpv.mpv_get_time_ns(nullptr), throwsArgumentError);
    expect(() => mpv.mpv_del_property(nullptr, nullptr), throwsArgumentError);
    expect(lookedUp, [
      'mpv_client_api_version',
      'mpv_get_time_ns',
      'mpv_del_property',
    ]);
  });

  test('event enums pass their C value, not their Dart index', () {
    final received = <int>[];
    final request =
        NativeCallable<
          Int Function(Pointer<mpv_handle>, UnsignedInt, Int)
        >.isolateLocal((Pointer<mpv_handle> ctx, int event, int enable) {
          received.add(event);
          return 0;
        }, exceptionalReturn: -1);
    try {
      final mpv = MPV.fromLookup(<T extends NativeType>(String name) {
        expect(name, 'mpv_request_event');
        return request.nativeFunction.cast<T>();
      });
      final event = mpv_event_id.fromValue(25);
      expect(event, mpv_event_id.MPV_EVENT_HOOK);
      expect(event.index, isNot(event.value));
      expect(mpv.mpv_request_event(nullptr, event, 1), 0);
      expect(received, [25]);
    } finally {
      request.close();
    }
  });

  test('C struct sizes and enum values match Dart FFI', () async {
    final header =
        Platform.environment['MPV_HEADER'] ??
        File('headers/mpv/client.h').absolute.path;
    final sizes = <String, int>{
      'mpv_node': sizeOf<mpv_node>(),
      'mpv_node_list': sizeOf<mpv_node_list>(),
      'mpv_byte_array': sizeOf<mpv_byte_array>(),
      'mpv_event': sizeOf<mpv_event>(),
      'mpv_event_property': sizeOf<mpv_event_property>(),
      'mpv_event_log_message': sizeOf<mpv_event_log_message>(),
      'mpv_event_start_file': sizeOf<mpv_event_start_file>(),
      'mpv_event_end_file': sizeOf<mpv_event_end_file>(),
      'mpv_event_client_message': sizeOf<mpv_event_client_message>(),
      'mpv_event_hook': sizeOf<mpv_event_hook>(),
      'mpv_event_command': sizeOf<mpv_event_command>(),
    };
    final enums = <String, int>{
      for (final entry in mpv_end_file_reason.values) entry.name: entry.value,
      for (final entry in mpv_error.values) entry.name: entry.value,
      for (final entry in mpv_event_id.values) entry.name: entry.value,
      for (final entry in mpv_format.values) entry.name: entry.value,
      for (final entry in mpv_log_level.values) entry.name: entry.value,
    };
    final temporary = Directory.systemTemp.createTempSync('mpv-abi-');
    try {
      final source = File('${temporary.path}/probe.c');
      source.writeAsStringSync(
        [
          '#include <stdio.h>',
          '#include "${header.replaceAll('\\', '/')}"',
          'int main(void) {',
          for (final name in sizes.keys)
            'printf("$name=%zu\\n", sizeof($name));',
          for (final name in enums.keys) 'printf("$name=%d\\n", (int)$name);',
          for (final name in [
            'mpv_format',
            'mpv_event_id',
            'mpv_log_level',
            'mpv_end_file_reason',
            'mpv_error',
          ])
            '_Static_assert(sizeof($name) == sizeof(int), "enum ABI");',
          'return 0; }',
        ].join('\n'),
      );
      final executable = '${temporary.path}/probe';
      final compile = await Process.run(Platform.environment['CC'] ?? 'cc', [
        '-std=c11',
        source.path,
        '-o',
        executable,
      ]);
      expect(compile.exitCode, 0, reason: '${compile.stderr}');
      final run = await Process.run(executable, []);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      final actual = <String, int>{
        for (final line in (run.stdout as String).trim().split('\n'))
          line.split('=')[0]: int.parse(line.split('=')[1]),
      };
      expect(actual, {...sizes, ...enums});
    } finally {
      temporary.deleteSync(recursive: true);
    }
  });
}
