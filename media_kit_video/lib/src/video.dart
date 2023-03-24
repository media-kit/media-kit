/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:media_kit_video/src/video_controller.dart';

/// {@template video}
///
/// Video
/// -----
/// [Video] widget is used to display video output inside Flutter widget tree.
///
/// Use [VideoController] to initialize & handle the video rendering.
///
/// **Example:**
///
/// ```dart
/// /// Create a [Player] from `package:media_kit`.
/// final player = Player();
/// /// Create a [VideoController] from `package:media_kit_video`.
/// VideoController? controller;
///
/// @override
/// void initState() {
///   super.initState();
///   Future.microtask(() async {
///     controller = await VideoController.create(player.handle);
///     setState(() {});
///   });
/// }
///
/// @override
/// void dispose() {
///   Future.microtask(() async {
///     await controller?.dispose();
///     await player.dispose();
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       /// Use [Video] widget to display video output.
///       child: Video(
///         controller: controller,
///       ),
///     ),
///   );
/// }
///
/// ```
///
/// {@endtemplate}
class Video extends StatefulWidget {
  /// The [VideoController] reference to control this [Video] output & connect with [Player] from `package:media_kit`.
  final VideoController? controller;

  /// Height of this viewport.
  final double? width;

  /// Width of this viewport.
  final double? height;

  /// Alignment of the viewport.
  final Alignment alignment;

  /// Fit of the viewport.
  final BoxFit fit;

  /// Preferred aspect ratio of the viewport.
  final double? aspectRatio;

  /// Background color to fill the video background.
  final Color fill;

  /// Filter quality of the [Texture] widget displaying the video output.
  final FilterQuality filterQuality;

  /// {@macro video}
  const Video({
    Key? key,
    required this.controller,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.aspectRatio,
    this.fill = const Color(0xFF000000),
    this.filterQuality = FilterQuality.low,
  }) : super(key: key);

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final aspectRatio = widget.aspectRatio;
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: widget.fill,
      child: ClipRect(
        child: FittedBox(
          alignment: widget.alignment,
          fit: widget.fit,
          child: controller == null
              ? const SizedBox.shrink()
              : ValueListenableBuilder<int?>(
                  valueListenable: controller.id,
                  builder: (context, id, _) {
                    return ValueListenableBuilder<Rect?>(
                      valueListenable: controller.rect,
                      builder: (context, rect, _) {
                        if (id != null && rect != null) {
                          return SizedBox(
                            // Apply aspect ratio if provided.
                            width: aspectRatio == null
                                ? rect.width
                                : rect.height * aspectRatio,
                            height: rect.height,
                            child: Stack(
                              children: [
                                const SizedBox(),
                                Positioned.fill(
                                  child: Texture(
                                    textureId: id,
                                    filterQuality: widget.filterQuality,
                                  ),
                                ),
                                // Keep the |Texture| hidden before the first frame renders. In native implementation, if
                                // no default frame size is passed (through VideoController), a starting 1 pixel sized
                                // texture/surface is created to initialize the render context & check for H/W support.
                                // This is then resized based on the video dimensions & accordingly texture ID, texture,
                                // EGLDisplay, EGLSurface etc. (depending upon platform) are also changed.
                                // Just don't show that 1 pixel texture to the UI.
                                // NOTE: Unmounting |Texture| causes the |MarkTextureFrameAvailable| to not do anything.
                                if (rect.width <= 1.0 && rect.height <= 1.0)
                                  Positioned.fill(
                                    child: Container(
                                      color: widget.fill,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
