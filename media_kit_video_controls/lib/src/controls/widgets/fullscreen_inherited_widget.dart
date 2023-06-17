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
class FullScreenInheritedWidget extends InheritedWidget {
  const FullScreenInheritedWidget({
    super.key,
    required super.child,
  });

  static FullScreenInheritedWidget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FullScreenInheritedWidget>();
  }

  static FullScreenInheritedWidget of(BuildContext context) {
    final FullScreenInheritedWidget? result = maybeOf(context);
    assert(
      result != null,
      'No [FullScreenInheritedWidget] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(FullScreenInheritedWidget oldWidget) =>
      identical(this, oldWidget);
}
