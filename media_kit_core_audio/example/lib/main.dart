import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final List<FileSystemEntity> dir =
      File(Platform.resolvedExecutable).parent.listSync(recursive: true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('package:media_kit_core_audio'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entity in dir)
                  Text(
                    entity.path,
                    style: TextStyle(
                      fontWeight: entity.toString().contains('mpv-2.dll')
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
