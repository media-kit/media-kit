/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';

import 'package:media_kit/src/models/media.dart';

import '../../common/sources.dart';

void main() {
  setUp(sources.prepare);
  test(
    'media-uri-normalization-network',
    () {
      for (final source in sources.network) {
        final test = source;
        print(test);
        expect(
          Media.normalizeURI(source),
          equals(source),
        );
        expect(
          Media(source).uri,
          equals(source),
        );
      }
    },
  );
  test(
    'media-uri-normalization-file',
    () async {
      // Path
      for (final source in sources.file) {
        final test = source;
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
      // file:// URI
      for (final source in sources.file) {
        final test = Uri.file(source).toString();
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
    },
    skip: Platform.isWindows,
  );
  test(
    'media-uri-normalization-file',
    () async {
      // Path: forward slash separators
      for (final source in sources.file) {
        final test = source;
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
      // Path: backwards slash separators
      for (final source in sources.file) {
        final test = source.replaceAll('/', r'\');
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
      // file:/// URI
      for (final source in sources.file) {
        final test = Uri.file(source).toString();
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
      // file:// URI
      for (final source in sources.file) {
        final test =
            Uri.file(source).toString().replaceAll('file:///', 'file://');
        print(test);
        expect(
          Media.normalizeURI(test),
          equals(source),
        );
        expect(
          Media(test).uri,
          equals(source),
        );
      }
    },
    skip: !Platform.isWindows,
  );
  test(
    'media-uri-normalization-encode-asset-key',
    () {
      expect(
        Media.encodeAssetKey('asset://videos/video_0.mp4'),
        equals('videos/video_0.mp4'),
      );
      expect(
        Media.encodeAssetKey('asset:///videos/video_0.mp4'),
        equals('videos/video_0.mp4'),
      );
      // Non ASCII characters.
      expect(
        Media.encodeAssetKey('asset://audios/う.wav'),
        equals('audios/%E3%81%86.wav'),
      );
      expect(
        Media.encodeAssetKey('asset:///audios/う.wav'),
        equals('audios/%E3%81%86.wav'),
      );
    },
  );
}
