import 'package:flutter/material.dart';

class Responsive {
  // Reference width for scaling (iPhone SE/mini = 375px)
  static const double _referenceWidth = 375.0;
  static const double _referenceHeight = 812.0;
  static const double _tabletBreakpoint = 600.0;
  static const double _largeTabletBreakpoint = 900.0;

  // ─── Core Scale Factors ───────────────────────────────────────────

  /// Width-based scale factor, capped at 600px to prevent oversized elements on tablets
  static double scale(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > _tabletBreakpoint) {
      screenWidth = _tabletBreakpoint;
    }
    return screenWidth / _referenceWidth;
  }

  /// Height-based scale factor for vertical elements, capped at 1000px
  static double heightScale(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight > 1000) {
      screenHeight = 1000;
    }
    return screenHeight / _referenceHeight;
  }

  // ─── Device Type Checks ───────────────────────────────────────────

  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < _tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _tabletBreakpoint && width < _largeTabletBreakpoint;
  }

  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= _largeTabletBreakpoint;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// True when the device is a tablet (>= 600px width) AND in landscape orientation
  static bool isTabletLandscape(BuildContext context) {
    return isLandscape(context) && (isTablet(context) || isLargeTablet(context));
  }

  // ─── Landscape-Adapted Helpers ────────────────────────────────────

  /// Compact height for headers/toolbars in landscape on tablets.
  /// Returns a reduced value when in tablet landscape, otherwise the original.
  static double compactHeight(BuildContext context, double value) {
    if (isTabletLandscape(context)) {
      return value * 0.6;
    }
    return height(context, value);
  }

  /// Landscape-adapted font size: slightly smaller on tablet landscape to fit more content
  static double landscapeFontSize(BuildContext context, double value) {
    if (isTabletLandscape(context)) {
      return value * scale(context) * 0.85;
    }
    return fontSize(context, value);
  }

  /// Max content width for reading-style text to keep line length comfortable
  static double readingMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isTabletLandscape(context)) {
      // In landscape, cap at a comfortable reading width (max ~700px)
      return screenWidth > 700 ? 700 : screenWidth;
    }
    if (screenWidth > _tabletBreakpoint) {
      return _tabletBreakpoint;
    }
    return screenWidth;
  }

  // ─── Responsive Dimension Helpers ─────────────────────────────────

  /// Scale a width value based on screen width
  static double width(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale a height value based on screen height
  static double height(BuildContext context, double value) {
    return value * heightScale(context);
  }

  /// Scale a dimension (uses width scale for consistency)
  static double dim(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale font size based on screen width
  static double fontSize(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale icon size based on screen width
  static double iconSize(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale padding/margin based on screen width
  static double padding(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale border radius based on screen width
  static double radius(BuildContext context, double value) {
    return value * scale(context);
  }

  // ─── Max Content Width ────────────────────────────────────────────

  /// Maximum content width to prevent overly wide text on tablets
  static double maxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > _tabletBreakpoint) {
      return _tabletBreakpoint;
    }
    return screenWidth;
  }

  // ─── Responsive Padding/Margin Presets ────────────────────────────

  /// Standard screen horizontal padding
  static EdgeInsets screenPadding(BuildContext context) {
    final h = padding(context, 16);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Horizontal padding for content areas
  static EdgeInsets horizontalPadding(BuildContext context) {
    final h = padding(context, 20);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Standard symmetric padding
  static EdgeInsets symmetricPadding(BuildContext context,
      {double horizontal = 16, double vertical = 8}) {
    return EdgeInsets.symmetric(
      horizontal: padding(context, horizontal),
      vertical: padding(context, vertical),
    );
  }

  // ─── Responsive Box Constraints ───────────────────────────────────

  /// Max width constraint for content on tablets
  static BoxConstraints maxWidthConstraint(BuildContext context) {
    return BoxConstraints(maxWidth: maxContentWidth(context));
  }

  // ─── Existing Text Styles (Enhanced) ──────────────────────────────

  static TextStyle chapterTitle(
    BuildContext context, {
    double userScale = 1.0,
    String fontFamily = '',
  }) {
    return TextStyle(
      fontSize: landscapeFontSize(context, 22) * userScale,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF4A0E00),
      fontFamily: fontFamily,
    );
  }

  static TextStyle songBody(BuildContext context, {double userScale = 1.0}) {
    return TextStyle(
      fontSize: landscapeFontSize(context, 18) * userScale,
      height: 1.6,
      color: const Color(0xFF2C1A0B),
    );
  }
}

// Keep the old ResponsiveText class for backward compatibility
class ResponsiveText {
  static double getScaleFactor(BuildContext context) {
    return Responsive.scale(context);
  }

  static TextStyle chapterTitle(
    BuildContext context, {
    double userScale = 1.0,
    String fontFamily = '',
  }) {
    return Responsive.chapterTitle(context, userScale: userScale, fontFamily: fontFamily);
  }

  static TextStyle songBody(BuildContext context, {double userScale = 1.0}) {
    return Responsive.songBody(context, userScale: userScale);
  }
}
