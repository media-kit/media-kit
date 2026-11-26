import 'package:flutter/widgets.dart';

class DisposeSafeNotifier<T> extends ValueNotifier<T> {
  DisposeSafeNotifier(super._value);

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
