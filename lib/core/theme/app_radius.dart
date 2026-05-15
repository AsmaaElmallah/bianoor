import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  // Slightly inflated radii for a soft “clay” silhouette (still RTL-safe).
  static const double xs = 9.0;
  static const double sm = 13.0;
  static const double md = 18.0;
  static const double lg = 28.0;
  static const double xl = 44.0;
  static const double xxl = 48.0;
  static const double full = 9999.0;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}
