import 'package:flutter/material.dart';

import 'tests/01.single_player_single_video.dart';
import 'tests/02.single_player_multiple_video.dart';
import 'tests/03.multiple_player_multiple_video.dart';
import 'tests/04.tabs_test.dart';
import 'tests/05.stress_test.dart';
import 'tests/06.paint_first_frame.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text(
              '01.single_player_single_video.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SinglePlayerSingleVideoScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              '02.single_player_multiple_video.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SinglePlayerMultipleVideoScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              '03.multiple_player_multiple_video.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const MultiplePlayerMultipleVideoScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              '04.tabs_test.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TabsTest(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              '05.stress_test.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StressTestScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              '06.paint_first_frame.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              paintFirstFrame(context);
            },
          ),
        ],
      ),
    );
  }
}
