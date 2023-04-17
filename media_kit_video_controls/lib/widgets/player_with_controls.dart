import 'package:media_kit_video/src/video.dart';
import 'package:media_kit_video_controls/widgets/media_kit_player.dart';
import 'package:media_kit_video_controls/widgets/helpers/adaptive_controls.dart';
import 'package:media_kit_video_controls/widgets/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaKitController mediaKitController =
        MediaKitController.of(context);

    double calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget buildControls(
      BuildContext context,
      MediaKitController mediaKitController,
    ) {
      return mediaKitController.showControls
          ? mediaKitController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
      MediaKitController mediaKitController,
      BuildContext context,
    ) {
      return Stack(
        children: <Widget>[
          if (mediaKitController.placeholder != null)
            mediaKitController.placeholder!,
          InteractiveViewer(
            transformationController:
                mediaKitController.transformationController,
            maxScale: mediaKitController.maxScale,
            panEnabled: mediaKitController.zoomAndPan,
            scaleEnabled: mediaKitController.zoomAndPan,
            child: Center(
              child: AspectRatio(
                aspectRatio: mediaKitController.aspectRatio ?? 16 / 9,
                child: Video(controller: mediaKitController.videoController),
              ),
            ),
          ),
          if (mediaKitController.overlay != null) mediaKitController.overlay!,
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder: (
                BuildContext context,
                PlayerNotifier notifier,
                Widget? widget,
              ) =>
                  Visibility(
                visible: !notifier.hideStuff,
                child: AnimatedOpacity(
                  opacity: notifier.hideStuff ? 0.0 : 0.8,
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54),
                    child: SizedBox(),
                  ),
                ),
              ),
            ),
          if (!mediaKitController.isFullScreen)
            buildControls(context, mediaKitController)
          else
            SafeArea(
              bottom: false,
              child: buildControls(context, mediaKitController),
            ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: calculateAspectRatio(context),
          child: buildPlayerWithControls(mediaKitController, context),
        ),
      ),
    );
  }
}
