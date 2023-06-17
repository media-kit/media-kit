/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template fullscreen_inherited_widget}
///
/// Inherited widget used to identify whether parent [Video] is in fullscreen or not.
///
/// {@endtemplate}
class FullscreenInheritedWidget extends InheritedWidget {
  const FullscreenInheritedWidget({
    super.key,
    required super.child,
  });

  static FullscreenInheritedWidget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FullscreenInheritedWidget>();
  }

  static FullscreenInheritedWidget of(BuildContext context) {
    final FullscreenInheritedWidget? result = maybeOf(context);
    assert(
      result != null,
      'No [FullscreenInheritedWidget] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(FullscreenInheritedWidget oldWidget) =>
      identical(this, oldWidget);
}
