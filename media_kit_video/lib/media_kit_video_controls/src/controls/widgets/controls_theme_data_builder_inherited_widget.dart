/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template controls_theme_data_builder_inherited_widget}
///
/// Inherited widget which provides [controlsThemeDataBuilder] associated with the parent [Video] widget to descendant widgets.
///
/// {@endtemplate}
class ControlsThemeDataBuilderInheritedWidget extends InheritedWidget {
  final Widget Function(Widget)? controlsThemeDataBuilder;
  const ControlsThemeDataBuilderInheritedWidget({
    super.key,
    required this.controlsThemeDataBuilder,
    required super.child,
  });

  static ControlsThemeDataBuilderInheritedWidget? maybeOf(
      BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        ControlsThemeDataBuilderInheritedWidget>();
  }

  static ControlsThemeDataBuilderInheritedWidget of(BuildContext context) {
    final ControlsThemeDataBuilderInheritedWidget? result = maybeOf(context);
    assert(
      result != null,
      'No [ControlsThemeDataBuilderInheritedWidget] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(ControlsThemeDataBuilderInheritedWidget oldWidget) =>
      identical(controlsThemeDataBuilder, oldWidget.controlsThemeDataBuilder);
}
