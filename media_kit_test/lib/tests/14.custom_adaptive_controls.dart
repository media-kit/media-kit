import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_test/common/globals.dart';
import 'package:media_kit_test/common/sources/sources_native.dart';
import 'package:media_kit_test/common/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CustomAdaptiveControls extends StatefulWidget {
  const CustomAdaptiveControls({super.key});

  @override
  State<CustomAdaptiveControls> createState() => _CustomAdaptiveControlsState();
}

class _CustomAdaptiveControlsState extends State<CustomAdaptiveControls> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint(error));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  List<Widget> get items => [
        for (int i = 0; i < sources.length; i++)
          ListTile(
            title: Text(
              'Video $i',
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              player.open(Media(sources[i]));
            },
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return // Wrap [Video] widget with [MaterialVideoControlsTheme].
        MaterialVideoControlsTheme(
            normal: MaterialVideoControlsThemeData(
              // Modify theme options:
              buttonBarButtonSize: 24.0,
              buttonBarButtonColor: Colors.white,
              // Modify top button bar:
              topButtonBar: [
                const Spacer(),
                MaterialDesktopCustomButton(
                  onPressed: () {
                    debugPrint('Custom "Settings" button pressed.');
                  },
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
            fullscreen: const MaterialVideoControlsThemeData(
              // Modify theme options:
              displaySeekBar: false,
              automaticallyImplySkipNextButton: false,
              automaticallyImplySkipPreviousButton: false,
            ),
            child: // Wrap [Video] widget with [MaterialDesktopVideoControlsTheme].
                MaterialDesktopVideoControlsTheme(
              normal: MaterialDesktopVideoControlsThemeData(
                // Modify theme options:
                seekBarThumbColor: Colors.blue,
                seekBarPositionColor: Colors.blue,
                toggleFullscreenOnDoublePress: false,
                // Modify top button bar:
                topButtonBar: [
                  const Spacer(),
                  MaterialDesktopCustomButton(
                    onPressed: () {
                      debugPrint('Custom "Settings" button pressed.');
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
                // Modify bottom button bar:
                bottomButtonBar: const [
                  Spacer(),
                  MaterialDesktopPlayOrPauseButton(),
                  Spacer(),
                  MaterialFullscreenButton()
                ],
              ),
              fullscreen: const MaterialDesktopVideoControlsThemeData(),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('package:media_kit'),
                ),
                floatingActionButton: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'file',
                      tooltip: 'Open [File]',
                      onPressed: () => showFilePicker(context, player),
                      child: const Icon(Icons.file_open),
                    ),
                    const SizedBox(width: 16.0),
                    FloatingActionButton(
                      heroTag: 'uri',
                      tooltip: 'Open [Uri]',
                      onPressed: () => showURIPicker(context, player),
                      child: const Icon(Icons.link),
                    ),
                  ],
                ),
                body: SizedBox.expand(
                  child: horizontal
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Card(
                                        elevation: 8.0,
                                        clipBehavior: Clip.antiAlias,
                                        margin: const EdgeInsets.all(32.0),
                                        child: Video(
                                          controller: controller,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32.0),
                                  ],
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1.0, thickness: 1.0),
                            Expanded(
                              flex: 1,
                              child: ListView(
                                children: items,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            Video(
                              controller: controller,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width *
                                  9.0 /
                                  16.0,
                            ),
                            ...items,
                          ],
                        ),
                ),
              ),
            ));
  }
}
