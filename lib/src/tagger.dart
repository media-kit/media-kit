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
/// Pass [verbose] as `true` to receive duration & bitrate of the [parse]d [Media].
/// This is made optional because having `false` can result in massive performance benefits.
/// This parameter should be `true`, if you want to retrieve [duration] & [bitrate] in [parse] results.
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
  /// Pass [verbose] as `true` to receive duration & bitrate of the [parse]d [Media].
  /// This is made optional because having `false` can result in massive performance benefits.
  /// This parameter should be `true`, if you want to retrieve [duration] & [bitrate] in [parse] results.
  ///
  Tagger({
    bool create = true,
    this.verbose = false,
  }) {
    if (create) {
      _create();
    }
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
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _uri = media.uri;
    _directory = coverDirectory?.path;
    _path = cover?.absolute.path;
    await cover?.parent.create_();
    await coverDirectory?.create_();
    await _completer.future;
    _metadata = Completer();
    _duration = Completer();
    _bitrate = Completer();
    _command(
      [
        'loadfile',
        media.uri,
        'replace',
      ],
    );
    if (verbose) {
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
    }
    Map<String, String> metadata = await _metadata.future.timeout(timeout);
    if (verbose) {
      try {
        metadata['duration'] = await _duration.future.timeout(timeout);
      } catch (e) {
        //
      }
      try {
        metadata['bitrate'] = await _bitrate.future.timeout(timeout);
      } catch (e) {
        //
      }
    }
    metadata['uri'] = media.uri;
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
    // Raw `mpv_command` calls cause crash on Windows.
    final command = 'quit $code'.toNativeUtf8();
    mpv.mpv_command_string(
      _handle,
      command.cast(),
    );
    calloc.free(command);
  }

  Future<void> _handler(Pointer<generated.mpv_event> event) async {
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
      if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason ==
          generated.mpv_end_file_reason.MPV_END_FILE_REASON_ERROR) {
        if (!_metadata.isCompleted) {
          _metadata.completeError(FormatException('MPV_END_FILE_REASON_ERROR'));
        }
      }
      if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason ==
          generated.mpv_end_file_reason.MPV_END_FILE_REASON_EOF) {
        if (!_metadata.isCompleted) {
          _metadata.completeError(FormatException('MPV_END_FILE_REASON_EOF'));
        }
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

        // libmpv doesn't seem to read ALBUMARTIST.
        if (_uri!.toUpperCase().endsWith('.FLAC') &&
            !metadata.containsKey('album_artist') &&
            metadata.containsKey('artist')) {
          metadata['album_artist'] = splitArtists(metadata['artist']!)!.first;
        }
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
          final title = [null, ''].contains(metadata['title'])
              ? () {
                  // If the title is empty, use the filename.
                  if (Uri.parse(_uri!).isScheme('FILE')) {
                    return basename(Uri.parse(_uri!).toFilePath());
                  }
                  // Otherwise, use the URI's last path component.
                  else {
                    if (_uri!.endsWith('/')) {
                      _uri = _uri!.substring(0, _uri!.length - 1);
                    }
                    return _uri!.split('/').last;
                  }
                }()
              : metadata['title'];
          _command(
            [
              'screenshot-to-file',
              join(
                _directory!,
                '$title${metadata['album'] ?? 'Unknown Album'}${metadata['album_artist'] ?? 'Unknown Artist'}.PNG'
                    .replaceAll(RegExp(kArtworkFileNameRegex), ''),
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
  }

  Future<void> _create() async {
    if (libmpv == null) return;
    _handle = await create(
      libmpv!,
      _handler,
    );
    <String, int>{
      'metadata': generated.mpv_format.MPV_FORMAT_NODE,
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'audio-bitrate': generated.mpv_format.MPV_FORMAT_DOUBLE,
    }.forEach(
      (property, format) {
        final ptr = property.toNativeUtf8();
        mpv.mpv_observe_property(
          _handle,
          0,
          ptr.cast(),
          format,
        );
        calloc.free(ptr);
      },
    );
    <String, String>{
      if (verbose) ...{
        'ao': 'null',
      } else ...{
        'audio': 'no',
        'pause': 'yes',
      },
      'vo': 'null',
      'autoload-files': 'no',
      'hwdec': 'no',
      'osc': 'no',
      'cache-secs': '0',
      'cache': 'no',
      'demuxer-max-bytes': '1024',
      'demuxer-max-back-bytes': '1024',
      'demuxer-readahead-secs': '10',
    }.forEach(
      (k, v) {
        final property = k.toNativeUtf8(), value = v.toNativeUtf8();
        mpv.mpv_set_property_string(
          _handle,
          property.cast(),
          value.cast(),
        );
        calloc.free(property);
        calloc.free(value);
      },
    );
    _completer.complete();
  }

  /// Calls MPV command passed as [args]. Automatically freeds memory after command sending.
  void _command(List<String?> args) {
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      if (e == null) return nullptr.cast();
      return e.toNativeUtf8();
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    mpv.mpv_command(
      _handle,
      arr.cast(),
    );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  /// Loads the dynamic library & setups callbacks in advance.
  ///
  Future<void> open() => _create();

  static List<String>? splitArtists(String? tag) {
    if (tag == null) return null;
    const kExceptions = [
      r'AC/DC',
      r'Axwell /\ Ingrosso',
      r'Au/Ra',
    ];
    final exempted = <String>[];
    for (final exception in kExceptions) {
      if (tag.contains(exception)) {
        exempted.add(exception);
      }
    }
    for (final element in kExceptions) {
      tag = tag!.replaceAll(element, '');
    }
    final artists = tag!
        .split(RegExp(r';|//|/|\\|\|'))
        .map((e) => e.trim())
        .toList()
        .toSet()
        .toList()
      ..removeWhere((element) => element.isEmpty);
    return artists + exempted;
  }

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  final Completer<void> _completer = Completer();

  Completer<Map<String, String>> _metadata = Completer();
  Completer<String> _duration = Completer();
  Completer<String> _bitrate = Completer();

  /// Current URI
  String? _uri;

  /// Path where cover will be saved.
  String? _path;

  /// Path to parent folder where cover will be saved.
  String? _directory;

  /// Whether bitrate & duration compatiblity is required.
  final bool verbose;
}

/// Safely [create]s a [File] recursively.
extension on Directory {
  Future<void> create_() async {
    try {
      final prefix = Platform.isWindows &&
              !path.startsWith('\\\\') &&
              !path.startsWith(r'\\?\')
          ? r'\\?\'
          : '';
      await Directory(prefix + path).create(recursive: true);
    } catch (exception, stacktrace) {
      print(exception.toString());
      print(stacktrace.toString());
    }
  }
}

/// [String] used for regex-matching the invalid file-name characters & removing them when saving the artwork
/// of a particular media file to a given [Directory].
/// i.e. calling [Tagger.parse] with `coverDirectory` optional argument.
const kArtworkFileNameRegex = r'[\\/:*?""<>| ]';
