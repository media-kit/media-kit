import 'package:flutter/material.dart';

import 'tests/01.single_player_single_video.dart';
import 'tests/02.single_player_multiple_video.dart';
import 'tests/03.multiple_player_multiple_video.dart';
import 'tests/04.tabs_test.dart';
import 'tests/05.stress_test.dart';
import 'tests/06.paint_first_frame.dart';
import 'tests/07.video_controller_set_size.dart';

import 'common/sources/sources.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp(DownloadingScreen()));
  await prepareSources();
  runApp(const MyApp(PrimaryScreen()));
}

class MyApp extends StatelessWidget {
  final Widget child;
  const MyApp(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: child,
    );
  }
}

class PrimaryScreen extends StatelessWidget {
  const PrimaryScreen({super.key});

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
          ListTile(
            title: const Text(
              '07.video_controller_set_size.dart',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const VideoControllerSetSizeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DownloadingScreen extends StatelessWidget {
  const DownloadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: const Center(
        child: Text(
          'Downloading sample videos...',
          style: TextStyle(fontSize: 14.0),
        ),
      ),
    );
  }
}
