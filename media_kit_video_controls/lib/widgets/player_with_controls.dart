import 'package:media_kit_video_controls/widgets/media_kit_player.dart';
import 'package:media_kit_video_controls/widgets/helpers/adaptive_controls.dart';
import 'package:media_kit_video_controls/widgets/notifiers/index.dart';
import 'package:flutter/material.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({
    Key? key,
    required this.video,
  }) : super(key: key);

  Widget video;
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
              child: video,
            ),
          ),
          if (mediaKitController.overlay != null) mediaKitController.overlay!,
          StreamBuilder<bool>(
            stream: PlayerNotifier.of(context).hideStuffStream,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                return Visibility(
                  visible: !snapshot.data!,
                  child: AnimatedOpacity(
                    opacity: snapshot.data! ? 0.0 : 1,
                    duration: const Duration(
                      milliseconds: 350,
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black26),
                      child: SizedBox.expand(),
                    ),
                  ),
                );
              } else {
                return const Text('No PlayerNotifier initialized');
              }
            },
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
        child: buildPlayerWithControls(mediaKitController, context),
      ),
    );
  }
}
