import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final root = Platform.script.resolve('../../media_kit/');
  final header = Platform.script.resolve('headers/mpv/client.h');
  await FfiGenerator(
    input: Input(entryPoints: [header]),
    output: Output(
      style: DynamicLibraryBindings(wrapperName: 'MPV'),
      preamble:
          '// Generated from mpv v0.41.0 (Client API 2.5) with ffigen 23.0.0.',
      dart: DartOutput(
        path: root.resolve('lib/generated/libmpv/bindings.dart'),
      ),
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = node.originalName.startsWith('mpv_'),
        struct: (node) =>
            node.isIncluded = node.originalName.startsWith('mpv_'),
        enumClass: (node) =>
            node.isIncluded = node.originalName.startsWith('mpv_'),
        macroConstant: (node) =>
            node.isIncluded = node.originalName == 'MPV_CLIENT_API_VERSION',
      ),
    ],
  ).generate();
}
