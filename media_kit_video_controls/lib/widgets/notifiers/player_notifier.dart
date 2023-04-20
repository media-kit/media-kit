import 'dart:async';

import 'package:flutter/material.dart';

///
/// The new State-Manager for MediaKitVideo!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside mediaKit
///
class PlayerNotifier {
  // private constructor
  PlayerNotifier._(this._hideStuff);

  bool _hideStuff;

  bool get hideStuff => _hideStuff;

  final StreamController<bool> _hideStuffStream =
      StreamController<bool>.broadcast();
  Stream<bool> get hideStuffStream => _hideStuffStream.stream;

  // set method that updates the value and broadcasts it to the stream
  set hideStuff(bool value) {
    _hideStuff = value;
    _hideStuffStream.add(value);
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      true,
    );
  }

  // dispose method to close the stream controller
  void dispose() {
    _hideStuffStream.close();
  }

  static PlayerNotifier of(BuildContext context) {
    final mediaKitControllerProvider =
        context.dependOnInheritedWidgetOfExactType<PlayerNotifierProvider>()!;

    return mediaKitControllerProvider.notifier;
  }
}

class PlayerNotifierProvider extends InheritedWidget {
  const PlayerNotifierProvider({
    Key? key,
    required this.notifier,
    required Widget child,
  }) : super(key: key, child: child);

  final PlayerNotifier notifier;

  @override
  bool updateShouldNotify(PlayerNotifierProvider oldWidget) =>
      notifier != oldWidget.notifier;
}
