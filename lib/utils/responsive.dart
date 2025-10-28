import 'package:flutter/material.dart';

/// Lightweight responsive helpers for phones from ~1080x2424 and below.
///
/// Reference layout width = 390dp (common for 1080px devices at 2.75x).
/// We scale UI values by width with safe clamps to avoid extreme sizes.
class Responsive {
  static const double baseWidth = 390.0;
  static const double baseHeight = 844.0;

  /// Scale factor based on width, clamped for very small/large phones.
  static double scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Allow slight up/down scaling but keep touch sizes reasonable.
    return (w / baseWidth).clamp(0.80, 1.10);
  }

  /// Font scale with a slightly tighter clamp to keep text readable.
  static double fontScale(BuildContext context) {
    return scale(context).clamp(0.85, 1.08);
  }

  /// Convenience to scale any dimension (padding, radius, icon size, etc).
  static double s(BuildContext context, double value) => value * scale(context);

  /// Convenience to scale font size.
  static double f(BuildContext context, double size) => size * fontScale(context);

  /// Choose a safe childAspectRatio for summary grids across screens.
  /// Slightly tighter cards on narrow phones to avoid overflow.
  static double summaryCardAspectRatio(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 340) return 1.30; // very narrow (e.g., older small phones)
    if (w < 360) return 1.40;
    if (w < 390) return 1.50;
    return 1.60; // default for typical ~390dp width phones
  }
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get sw => screenSize.width;
  double get sh => screenSize.height;

  double rs(double value) => Responsive.s(this, value);
  double rf(double size) => Responsive.f(this, size);
  double get summaryAspect => Responsive.summaryCardAspectRatio(this);
}
