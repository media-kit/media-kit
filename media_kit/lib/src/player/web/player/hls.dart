@JS()
library hls_library;
import 'dart:html';

import 'package:js/js.dart';

@JS("Hls.isSupported")
external bool isHlsSupported();
@JS()
@staticInterop
class Hls{
  external factory Hls();
}
extension ExtensionHls on Hls {
  external void loadSource(String src);
  external void attachMedia(VideoElement video);
}