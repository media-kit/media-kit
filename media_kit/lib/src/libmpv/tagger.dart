/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:uri_parser/uri_parser.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

import 'package:media_kit/src/platform_tagger.dart';
import 'package:media_kit/src/libmpv/core/initializer.dart';
import 'package:media_kit/src/libmpv/core/utf8_fallback.dart';
import 'package:media_kit/src/libmpv/core/native_library.dart';
import 'package:media_kit/src/libmpv/core/fallback_bitrate_handler.dart';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/tagger_metadata.dart';

import 'package:media_kit/generated/libmpv/bindings.dart' as generated;

/// {@template libmpv_tagger}
///
/// Tagger
/// ------
///
/// Compatiblity has been tested with libmpv 0.28.0 or higher. The recommended version is 0.33.0 or higher.
///
/// {@endtemplate}
class Tagger extends PlatformTagger {
  /// {@macro libmpv_tagger}
  Tagger({required super.configuration}) {
    _create().then((_) {
      configuration.ready?.call();
    });
  }

  /// Disposes the [Tagger] instance & releases the resources.
  @override
  Future<void> dispose({int code = 0}) async {
    await _completer.future;
    // Raw `mpv_command` calls cause crash on Windows.
    final command = 'quit $code'.toNativeUtf8();
    _libmpv?.mpv_command_string(
      _handle,
      command.cast(),
    );
    calloc.free(command);
  }

  /// Parses a [Media] & returns its metadata.
  ///
  /// Optionally, following argument may be passed:
  ///
  /// * [cover] may be passed to save the cover art of the [Media] to the location.
  /// * [coverDirectory] may be passed to save the cover art of the [Media] to the directory.
  /// * [waitUntilCoverIsSaved] may be passed to wait until the cover art is saved.
  /// * [timeout] may be passed to set the timeout duration for the parsing operation.
  ///
  /// Throws [FormatException] if an invalid, corrupt or inexistent [Media] is passed.
  ///
  @override
  FutureOr<TaggerMetadata> parse(
    Media media, {
    File? cover,
    Directory? coverDirectory,
    bool waitUntilCoverIsSaved = false,
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
    if (configuration.verbose) {
      final name = 'pause'.toNativeUtf8();
      final flag = calloc<Int8>()..value = 0;
      _libmpv?.mpv_set_property(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        flag.cast(),
      );
      calloc.free(name);
      calloc.free(flag);
    }
    Map<String, String> metadata = await _metadata.future.timeout(timeout);
    if (configuration.verbose) {
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
    _libmpv?.mpv_command_string(
      _handle,
      stop.cast(),
    );
    calloc.free(stop);
    return serialize(metadata);
  }

  @override
  TaggerMetadata serialize(dynamic json) {
    assert(json['uri'] is String, 'Track URI cannot be null.');
    final String uri = json['uri'];
    final parser = URIParser(uri);
    String? trackName;
    int? albumLength;
    DateTime? timeAdded;
    List<String>? trackArtistNames;
    // Present in JSON.
    if (json['title'] is String) {
      trackName = json['title'];
    }
    // Not present in JSON. Extract from [File] name or URI segment.
    else {
      switch (parser.type) {
        case URIType.file:
          trackName = basename(parser.file!.path);
          break;
        case URIType.network:
          trackName = parser.uri!.pathSegments.last;
          break;
        default:
          trackName = uri;
          break;
      }
    }
    // Present in JSON.
    if (json['tracktotal'] is String) {
      albumLength = parseInteger(json['tracktotal']);
    } else if (json['track'] is String) {
      if (json['track'].contains('/')) {
        albumLength = parseInteger(json['track'].split('/').last);
      }
    }
    // Not present in JSON. Access from file system.
    switch (parser.type) {
      case URIType.file:
        timeAdded = parser.file!.lastModifiedSync_();
        break;
      default:
        timeAdded = DateTime.now();
        break;
    }
    trackArtistNames = splitArtistTag(json['artist']);

    // Assign fallback values.
    trackName ??= uri;
    albumLength ??= 1;
    timeAdded ??= DateTime.now();

    // Should never be, just for safety.
    if (trackArtistNames != null) {
      if (trackArtistNames.isEmpty) {
        trackArtistNames = null;
      }
    }

    return TaggerMetadata(
      uri: parser.result,
      trackName: trackName,
      albumName: json['album'],
      trackNumber: parseInteger(json['track']),
      discNumber: parseInteger(json['disc']),
      albumLength: albumLength,
      albumArtistName: json['album_artist'],
      trackArtistNames: trackArtistNames,
      year: json['year'] ?? splitDateTag(json['date']),
      timeAdded: timeAdded,
      duration: Duration(
          milliseconds: parseInteger(json['duration'] ?? '0')! ~/ 1000),
      bitrate: parseInteger(json['bitrate'] ?? '0')! ~/ 1000,
      genre: json['genre'],
      lyrics: json['lyrics'],
      authorName: json['author'],
      writerName: json['writer'],
      // Non-serialized data. Why not?
      data: json,
    );
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
        final duration = prop.ref.data.cast<Double>().value;
        if (!_duration.isCompleted) {
          _duration.complete((duration * 1e6 ~/ 1).toString());
        }
        try {
          // Handling FLAC bitrate calculation manually.
          if (FallbackBitrateHandler.isLocalFLACOrOGGFile(_uri!)) {
            final value = await FallbackBitrateHandler.calculateBitrate(
                  _uri!,
                  Duration(
                    seconds: duration ~/ 1,
                  ),
                ) *
                1e6 ~/
                1;
            _bitrate.complete(value.toString());
          }
        } catch (exception) {
          // Do nothing.
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-bitrate' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        try {
          // Handling FLAC bitrate calculation manually.
          if (!FallbackBitrateHandler.isLocalFLACOrOGGFile(_uri!)) {
            if (!_bitrate.isCompleted) {
              _bitrate.complete(
                  (prop.ref.data.cast<Double>().value * 1e6 ~/ 1).toString());
            }
          }
        } catch (exception) {
          // Do nothing.
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'metadata' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final metadata = <String, String>{};
        // Adding this try/catch clause because why not.
        // But in case of a native-sided memory corruption, this won't help anyway.
        try {
          final data = prop.ref.data.cast<generated.mpv_node>().ref.u.list;
          for (int i = 0; i < data.ref.num; i++) {
            // https://github.com/harmonoid/harmonoid/issues/331
            // [Utf8Pointer.toDartString] throws [FormatException] when the native `char[]` present at the address is corrupt (or maybe non-null terminated).
            // Never experienced this error personally.
            // Likely this is a problem on libmpv's side.
            try {
              metadata[data.ref.keys[i].cast<Utf8>().toDartString()] =
                  // NOTE (@alexmercerind): See [PointerUtf8Extension.toDartString_] for more info.
                  // Above linked issue has more information.
                  data.ref.values[i].u.string.cast<Utf8>().toDartString_();
            } catch (exception) {
              // Do nothing.
            }
          }
          final _ = {...metadata}.forEach(
            (key, value) {
              metadata[key.toLowerCase()] = value;
            },
          );
        } catch (exception) {
          // Do nothing.
        }
        // libmpv doesn't seem to read ALBUMARTIST on FLAC/OGG.
        // No longer checking for it. Use first `artist` as `album_artist` if `album_artist` is not present.
        if (!metadata.containsKey('album_artist') &&
            metadata.containsKey('artist')) {
          metadata['album_artist'] = splitArtistTag(metadata['artist']!)!.first;
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
          final parser = URIParser(_uri);
          String? trackName;
          // Present in JSON.
          if (metadata['title'] is String) {
            trackName = metadata['title'];
          }
          // Not present in JSON. Extract from [File] name or URI segment.
          else {
            switch (parser.type) {
              case URIType.file:
                trackName = basename(parser.file!.path);
                break;
              case URIType.network:
                trackName = parser.uri!.pathSegments.last;
                break;
              default:
                trackName = _uri;
                break;
            }
          }
          // NOTE: Following same contract as [Harmonoid](https://github.com/harmonoid/harmonoid).
          final moniker =
              '$trackName${metadata['album'] ?? 'Unknown Album'}${metadata['album_artist'] ?? 'Unknown Artist'}.PNG';
          _command(
            [
              'screenshot-to-file',
              join(
                _directory!,
                moniker.replaceAll(RegExp(r'[\\/:*?""<>| ]'), ''),
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
    final libmpv = await NativeLibrary.find(path: configuration.libmpv);
    _libmpv = generated.MPV(DynamicLibrary.open(libmpv));
    _handle = await create(
      libmpv,
      _handler,
    );
    <String, int>{
      'metadata': generated.mpv_format.MPV_FORMAT_NODE,
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'audio-bitrate': generated.mpv_format.MPV_FORMAT_DOUBLE,
    }.forEach(
      (property, format) {
        final ptr = property.toNativeUtf8();
        _libmpv?.mpv_observe_property(
          _handle,
          0,
          ptr.cast(),
          format,
        );
        calloc.free(ptr);
      },
    );
    <String, String>{
      'ao': 'null',
      'vo': 'null',
      'idle': 'yes',
      'pause': 'yes',
      'osc': 'no',
      'hwdec': 'no',
      'autoload-files': 'no',
      'cache': 'no',
      'cache-secs': '0',
      'demuxer-readahead-secs': '10',
      'demuxer-max-bytes': '1024',
      'demuxer-max-back-bytes': '1024',
    }.forEach(
      (k, v) {
        final property = k.toNativeUtf8(), value = v.toNativeUtf8();
        _libmpv?.mpv_set_property_string(
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

  /// Calls mpv command passed as [args]. Automatically freeds memory after command sending.
  void _command(List<String?> args) {
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      if (e == null) return nullptr.cast();
      return e.toNativeUtf8();
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    _libmpv?.mpv_command(
      _handle,
      arr.cast(),
    );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  /// Internal generated libmpv C API bindings.
  generated.MPV? _libmpv;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  final Completer<void> _completer = Completer();

  /// Current URI
  String? _uri;

  /// Path where cover will be saved.
  String? _path;

  /// Path to parent folder where cover will be saved.
  String? _directory;

  // For waiting on event callbacks.

  Completer<Map<String, String>> _metadata = Completer<Map<String, String>>();
  Completer<String> _duration = Completer<String>();
  Completer<String> _bitrate = Completer<String>();
}
