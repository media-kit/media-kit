import 'package:test/test.dart';
import 'package:media_kit/src/models/media.dart';

void main() {
  test(
    '.encodeAssetKey() encodes non-ASCII paths',
    () {
      final path = Media.encodeAssetKey('asset://assets/audios/う.wav');
      expect(path, equals('assets/audios/%E3%81%86.wav'));
    },
  );
}
