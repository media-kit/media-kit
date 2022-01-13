/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/models/media.dart';
import 'package:libmpv/src/dynamic_library.dart';
import 'package:libmpv/src/core/initializer.dart';

import 'package:libmpv/generated/bindings.dart' as generated;

/// ## Tagger
///
/// [Tagger] class provides high-level interface for retrieving metadata tags from a [Media].
///
/// ```dart
/// final tagger = Tagger();
/// var metadata = await tagger.parse(
///   Media('https://alexmercerind.github.io/music.m4a'),
///   cover: File('cover.jpg'),
/// );
/// ```
///
class Tagger {
  /// ## Tagger
  ///
  /// [Tagger] class provides high-level interface for retrieving metadata tags from a [Media].
  ///
  /// ```dart
  /// final tagger = Tagger();
  /// var metadata = await tagger.parse(
  ///   Media('https://alexmercerind.github.io/music.m4a'),
  ///   cover: File('cover.jpg'),
  /// );
  /// ```
  ///
  Tagger() {
    _create();
  }

  /// Parses a [Media] & returns its metadata as [Map].
  /// Pass [File] as [cover] where the [Media]'s album art will be extracted. No album art is extracted if [cover] is `null`.
  ///
  /// NOTE: Extracting [cover] can really degrade the performance. Do not pass [cover] when only metadata keys are needed.
  ///
  /// Throws exception if an invalid, corrupt or inexistent [Media] is passed.
  ///
  Future<Map<String, String>> parse(Media media, {File? cover}) async {
    _path = cover?.absolute.path;
    await cover?.parent.create(recursive: true);
    await _completer.future;
    _cover = Completer();
    _completer = Completer();
    _command(
      [
        'loadfile',
        media.uri,
        'replace',
      ],
    );
    if (_loaded) {
      await _completer.future;
      _completer = Completer();
    }
    _loaded = true;
    var name = 'pause'.toNativeUtf8();
    var flag = calloc<Int8>()..value = 0;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
    if (cover != null) await _cover.future;
    Map<String, String>? metadata = await _completer.future;
    return metadata!;
  }

  /// Disposes the [Tagger] instance & releases the resources.
  Future<void> dispose({int code = 0}) async {
    await _completer.future;
    _command(
      [
        'quit',
        code.toString(),
      ],
    );
    mpv.mpv_terminate_destroy(_handle);
  }

  Future<void> _create() async {
    _handle = await create(
      libmpvDynamicLibrary,
      (event) async {
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
          if (!_completer.isCompleted) _completer.complete(null);
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          var prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'metadata' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
            var metadata = <String, String>{};
            var data = prop.ref.data.cast<generated.mpv_node>().ref.u.list;
            for (int i = 0; i < data.ref.num; i++) {
              metadata[data.ref.keys[i].cast<Utf8>().toDartString()] =
                  data.ref.values[i].u.string.cast<Utf8>().toDartString();
            }
            if (_path != null) {
              _command(
                [
                  'screenshot-to-file',
                  _path!,
                  null,
                ],
              );
              if (!_cover.isCompleted) _cover.complete();
            }
            if (!_completer.isCompleted) _completer.complete(metadata);
          }
        }
      },
    );
    var property = 'metadata'.toNativeUtf8();
    mpv.mpv_observe_property(
      _handle,
      0,
      property.cast(),
      generated.mpv_format.MPV_FORMAT_NODE,
    );
    calloc.free(property);
    var vo = 'vo'.toNativeUtf8();
    var ao = 'ao'.toNativeUtf8();
    var value = 'null'.toNativeUtf8();
    mpv.mpv_set_option_string(
      _handle,
      vo.cast(),
      value.cast(),
    );
    mpv.mpv_set_option_string(
      _handle,
      ao.cast(),
      value.cast(),
    );
    calloc.free(vo);
    calloc.free(ao);
    calloc.free(value);
    _completer.complete();
  }

  /// Calls MPV command passed as [args]. Automatically freeds memory after command sending.
  void _command(List<String?> args) {
    final ptr = args
        .map((String? string) =>
            string == null ? nullptr : string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join('').length);
    for (int index = 0; index < args.length; index++) {
      arr[index] = ptr[index];
    }
    mpv.mpv_command(
      _handle,
      arr.cast(),
    );
    for (int i = 0; i < args.length; i++) {
      if (args[i] != null) {
        calloc.free(ptr[i]);
      }
    }
    calloc.free(arr);
  }

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  Completer<dynamic> _completer = Completer();

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  Completer<void> _cover = Completer();

  /// Path where cover will be saved.
  String? _path;

  /// Whether [parse] has been called before.
  bool _loaded = false;
}
