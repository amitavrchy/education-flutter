import 'package:flutter/widgets.dart';

/// 4-point spacing scale and radius tokens, shared by every screen.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg, vertical: lg);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
}
