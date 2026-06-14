import 'package:flutter/material.dart';

/// Spacing scale used across the app. These are the values that were already
/// repeated inline everywhere (4 / 8 / 12 / 16 / 24); naming them keeps padding
/// and gaps consistent instead of being magic numbers per screen.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner-radius scale. `sm` = inputs/small badges, `md` = cards/sections,
/// `lg` = hero / large containers.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

/// Minimum interactive height for full-width rows/tiles (Fitts's Law — comfy
/// touch targets).
const double kMinTouchTarget = 48;
