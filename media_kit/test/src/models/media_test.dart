import 'package:test/test.dart';
import 'package:media_kit/src/models/media.dart';

void main() {
  test('.encodePath() encodes non-ASCII paths', () {
    final path = Media.encodePath('assets/audios/う.wav');
    expect(path, equals('assets/audios/%E3%81%86.wav'));
  });
}
