/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/models/media.dart';
import 'package:libmpv/src/dynamic_library.dart';
import 'package:libmpv/src/core/initializer.dart';

import 'package:libmpv/generated/bindings.dart' as generated;
import 'package:path/path.dart';

/// ## Tagger
///
/// [Tagger] class provides high-level interface for retrieving metadata tags from a [Media].
///
/// ```dart
/// final tagger = Tagger();
/// final metadata = await tagger.parse(
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
  /// final metadata = await tagger.parse(
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
  Future<Map<String, String>> parse(
    Media media, {
    File? cover,
    Directory? coverDirectory,
    bool duration = false,
    bool bitrate = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _end_file_count = 0;
    _directory = coverDirectory?.path;
    _path = cover?.absolute.path;
    await cover?.parent.create(recursive: true);
    await coverDirectory?.create(recursive: true);
    await _completer.future;
    _metadata = Completer();
    _duration = Completer();
    _bitrate = Completer();
    <String, int>{
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'audio-bitrate': generated.mpv_format.MPV_FORMAT_DOUBLE,
    }.forEach((property, format) {
      final ptr = property.toNativeUtf8();
      mpv.mpv_observe_property(
        _handle,
        0,
        ptr.cast(),
        format,
      );
      calloc.free(ptr);
    });
    _command(
      [
        'loadfile',
        media.uri,
        'replace',
      ],
    );
    final name = 'pause'.toNativeUtf8();
    final flag = calloc<Int8>()..value = 0;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
    Map<String, String> metadata = await _metadata.future.timeout(timeout);
    if (duration) {
      metadata['duration'] = await _duration.future.timeout(timeout);
    }
    if (bitrate) {
      metadata['bitrate'] = await _bitrate.future.timeout(timeout);
    }
    final stop = 'stop'.toNativeUtf8().cast();
    mpv.mpv_command_string(
      _handle,
      stop.cast(),
    );
    calloc.free(stop);
    return metadata;
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
      mpvDynamicLibraryPath,
      (event) async {
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
          _end_file_count++;
          if (_end_file_count > 1 && !_metadata.isCompleted) {
            _metadata.complete({});
          }
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          final prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'duration' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            if (!_duration.isCompleted) {
              _duration.complete(
                  (prop.ref.data.cast<Double>().value * 1e6 ~/ 1).toString());
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-bitrate' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            if (!_bitrate.isCompleted) {
              _bitrate.complete(
                  (prop.ref.data.cast<Double>().value * 1e6 ~/ 1).toString());
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'metadata' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
            final metadata = <String, String>{};
            final data = prop.ref.data.cast<generated.mpv_node>().ref.u.list;
            for (int i = 0; i < data.ref.num; i++) {
              metadata[data.ref.keys[i].cast<Utf8>().toDartString()] =
                  data.ref.values[i].u.string.cast<Utf8>().toDartString();
            }
            final _ = {...metadata}.forEach(
              (key, value) {
                metadata[key.toLowerCase()] = value;
              },
            );
            if (_path != null) {
              _command(
                [
                  'screenshot-to-file',
                  _path!,
                  null,
                ],
              );
            }
            if (_directory != null) {
              _command(
                [
                  'screenshot-to-file',
                  join(
                    _directory!,
                    '${metadata['album'] ?? 'Unknown Album'}${metadata['album_artist'] ?? 'Unknown Artist'}'
                            .replaceAll(RegExp(r'[\\/:*?""<>| ]'), '') +
                        '.PNG',
                  ),
                  null,
                ],
              );
            }
            if (!_metadata.isCompleted) {
              _metadata.complete(metadata);
            }
          }
        }
      },
    );
    final property = 'metadata'.toNativeUtf8();
    mpv.mpv_observe_property(
      _handle,
      0,
      property.cast(),
      generated.mpv_format.MPV_FORMAT_NODE,
    );
    calloc.free(property);
    final vo = 'vo'.toNativeUtf8();
    final ao = 'ao'.toNativeUtf8();
    final value = 'null'.toNativeUtf8();
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
  final Completer<void> _completer = Completer();

  Completer<Map<String, String>> _metadata = Completer();
  Completer<String> _duration = Completer();
  Completer<String> _bitrate = Completer();

  /// Path where cover will be saved.
  String? _path;

  /// Path to parent folder where cover will be saved.
  String? _directory;

  int _end_file_count = 0;
}
