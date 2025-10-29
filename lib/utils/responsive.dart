import 'package:flutter/material.dart';

/// Responsive helpers for phones, tablets, and larger screens.
///
/// Breakpoints:
/// - Mobile: < 600dp (smartphones)
/// - Tablet: 600dp - 1024dp (tablets)
/// - Desktop: > 1024dp (large tablets/desktops)
class Responsive {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  
  static const double baseWidth = 390.0;
  static const double baseHeight = 844.0;

  /// Check if device is mobile (smartphone)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  /// Check if device is desktop/large screen
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Scale factor based on width, with different ranges for device types
  static double scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    
    if (isDesktop(context)) {
      // Desktop: scale up moderately
      return (w / baseWidth).clamp(1.2, 1.8);
    } else if (isTablet(context)) {
      // Tablet: scale up slightly
      return (w / baseWidth).clamp(1.1, 1.5);
    } else {
      // Mobile: original behavior
      return (w / baseWidth).clamp(0.80, 1.10);
    }
  }

  /// Font scale with device-specific ranges
  static double fontScale(BuildContext context) {
    if (isDesktop(context)) {
      return scale(context).clamp(1.1, 1.3);
    } else if (isTablet(context)) {
      return scale(context).clamp(1.0, 1.2);
    } else {
      return scale(context).clamp(0.85, 1.08);
    }
  }

  /// Convenience to scale any dimension (padding, radius, icon size, etc).
  static double s(BuildContext context, double value) => value * scale(context);

  /// Convenience to scale font size.
  static double f(BuildContext context, double size) => size * fontScale(context);

  /// Grid cross axis count based on screen size
  static int gridCrossAxisCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Choose a safe childAspectRatio for summary grids across screens.
  static double summaryCardAspectRatio(BuildContext context) {
    if (isDesktop(context)) {
      return 1.8; // Wider cards for desktop
    } else if (isTablet(context)) {
      return 1.7; // Slightly wider for tablet
    } else {
      // Mobile: original behavior
      final w = MediaQuery.of(context).size.width;
      if (w < 340) return 1.30;
      if (w < 360) return 1.40;
      if (w < 390) return 1.50;
      return 1.60;
    }
  }

  /// Horizontal padding based on device type
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32.0;
    if (isTablet(context)) return 24.0;
    return 16.0;
  }

  /// Get value based on device type
  static T valueWhen<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Max content width for large screens (to prevent stretching)
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200.0;
    if (isTablet(context)) return 900.0;
    return double.infinity;
  }
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get sw => screenSize.width;
  double get sh => screenSize.height;

  double rs(double value) => Responsive.s(this, value);
  double rf(double size) => Responsive.f(this, size);
  double get summaryAspect => Responsive.summaryCardAspectRatio(this);
  
  // Device type helpers
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  
  // Grid helpers
  int gridCount({int mobile = 2, int tablet = 3, int desktop = 4}) =>
      Responsive.gridCrossAxisCount(this, mobile: mobile, tablet: tablet, desktop: desktop);
  
  // Padding helpers
  double get horizontalPadding => Responsive.horizontalPadding(this);
  
  // Max width helper
  double get maxContentWidth => Responsive.maxContentWidth(this);
}
