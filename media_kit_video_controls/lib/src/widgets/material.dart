/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template material_video_controls}
///
/// [Video] controls which use Material design.
///
/// {@endtemplate}
Widget MaterialVideoControls(
  BuildContext context,
  VideoController controller,
) {
  final data = MaterialVideoControlsTheme.maybeOf(context)?.data ??
      const MaterialVideoControlsThemeData();
  return _MaterialVideoControls(controller: controller, data: data);
}

/// {@template material_video_controls_theme_data}
///
/// Theming related data for [MaterialVideoControls]. These values are used to theme the descendant [MaterialVideoControls].
///
/// {@endtemplate}
class MaterialVideoControlsThemeData {
  const MaterialVideoControlsThemeData();
}

const kVideoControlsMouseHoverDuration = Duration(seconds: 3);
const kVideoControlsTransitionDuration = Duration(milliseconds: 150);

/// {@template material_video_controls_theme}
///
/// Inherited widget which provides [MaterialVideoControlsThemeData] to descendant widgets.
///
/// {@endtemplate}
class MaterialVideoControlsTheme extends InheritedWidget {
  final MaterialVideoControlsThemeData data;
  const MaterialVideoControlsTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static MaterialVideoControlsTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MaterialVideoControlsTheme>();
  }

  static MaterialVideoControlsTheme of(BuildContext context) {
    final MaterialVideoControlsTheme? result = maybeOf(context);
    assert(result != null, 'No MaterialVideoControlsTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(MaterialVideoControlsTheme oldWidget) =>
      data != oldWidget.data;
}

/// {@macro material_video_controls}
class _MaterialVideoControls extends StatefulWidget {
  final VideoController controller;
  final MaterialVideoControlsThemeData data;
  const _MaterialVideoControls({
    Key? key,
    required this.controller,
    required this.data,
  }) : super(key: key);

  @override
  State<_MaterialVideoControls> createState() => _MaterialVideoControlsState();
}

/// {@macro material_video_controls}
class _MaterialVideoControlsState extends State<_MaterialVideoControls> {
  bool visible = false;

  Timer? _timer;

  void onEnter() {
    setState(() {
      visible = true;
    });
    _timer?.cancel();
    _timer = Timer(kVideoControlsMouseHoverDuration, () {
      setState(() {
        visible = false;
      });
    });
  }

  void onHover() {
    setState(() {
      visible = true;
    });
    _timer?.cancel();
    _timer = Timer(kVideoControlsMouseHoverDuration, () {
      setState(() {
        visible = false;
      });
    });
  }

  void onExit() {
    setState(() {
      visible = false;
    });
    _timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => onHover(),
      onExit: (_) => onExit(),
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: kVideoControlsTransitionDuration,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [
                    0.5,
                    1.0,
                  ],
                  colors: [
                    Colors.transparent,
                    Colors.black38,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
