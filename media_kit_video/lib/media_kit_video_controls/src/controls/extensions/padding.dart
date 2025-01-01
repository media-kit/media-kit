import 'package:flutter/widgets.dart';

extension EdgeInsetsGeometryExt on EdgeInsetsGeometry? {
  double get bottom {
    final value = this;

    if (value == null) return 0.0;
    if (value is EdgeInsets) return value.bottom;
    if (value is EdgeInsetsDirectional) return value.bottom;

    return 0.0;
  }

  double get top {
    final value = this;
    if (value == null) return 0.0;
    if (value is EdgeInsets) return value.top;
    if (value is EdgeInsetsDirectional) return value.top;

    return 0.0;
  }

  double get start {
    final value = this;
    if (value == null) return 0.0;
    if (value is EdgeInsets) return value.left;
    if (value is EdgeInsetsDirectional) return value.start;

    return 0.0;
  }

  double get end {
    final value = this;
    if (value == null) return 0.0;
    if (value is EdgeInsets) return value.right;
    if (value is EdgeInsetsDirectional) return value.end;

    return 0.0;
  }
}
