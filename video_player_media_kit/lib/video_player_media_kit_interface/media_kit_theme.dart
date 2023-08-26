import 'package:flutter/material.dart';

class MediaKitTheme extends InheritedWidget {
  final Color fillColor;

  const MediaKitTheme({
    super.key,
    required this.fillColor,
    required super.child,
  });

  static MediaKitTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MediaKitTheme>();
  }

  static MediaKitTheme of(BuildContext context) {
    final MediaKitTheme? result = maybeOf(context);
    assert(
      result != null,
      'No [MediaKitTheme] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(MediaKitTheme oldWidget) =>
      identical(fillColor, oldWidget.fillColor);
}
