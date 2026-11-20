import 'package:flutter/material.dart';

class Responsive {
  // Reference width for scaling (iPhone SE/mini = 375px)
  static const double _referenceWidth = 375.0;
  static const double _referenceHeight = 812.0;
  static const double _tabletBreakpoint = 600.0;
  static const double _largeTabletBreakpoint = 900.0;

  /// Widest the main app content (lists, settings, forms) is allowed to grow
  /// on tablets. Keeping a comfortable column avoids the stretched, oversized
  /// look that full-width phone layouts get on large screens.
  static const double _contentMaxWidth = 760.0;

  /// Long Tamil lines become hard to follow when they run the full width of a
  /// tablet, so reading text gets an even tighter cap.
  static const double _readingPortraitMaxWidth = 700.0;
  static const double _readingLandscapeMaxWidth = 760.0;

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

  /// True for a tablet held upright.
  static bool isTabletPortrait(BuildContext context) {
    return isLandscape(context) == false &&
        (isTablet(context) || isLargeTablet(context));
  }

  /// True when the device is a tablet (>= 600px width) AND in landscape orientation
  static bool isTabletLandscape(BuildContext context) {
    return isLandscape(context) &&
        (isTablet(context) || isLargeTablet(context));
  }

  // ─── Landscape-Adapted Helpers ────────────────────────────────────

  /// Compact height for headers/toolbars in landscape on tablets.
  /// Returns a reduced value when in tablet landscape, otherwise the original.
  static double compactHeight(BuildContext context, double value) {
    if (isTabletLandscape(context)) {
      // Scale with the device as well: multiplying only by 0.6 used to make
      // landscape toolbars shorter than the icons they contain.
      return value * heightScale(context) * 0.8;
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
    final maxWidth = isLandscape(context)
        ? _readingLandscapeMaxWidth
        : _readingPortraitMaxWidth;
    return screenWidth > maxWidth ? maxWidth : screenWidth;
  }

  /// Max width for general app content (chapter lists, settings, forms).
  ///
  /// On phones this equals the screen width so the existing layout is
  /// untouched. On tablets the content is centred in a readable column
  /// instead of stretching edge to edge.
  static double contentMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > _contentMaxWidth ? _contentMaxWidth : screenWidth;
  }

  /// Extra horizontal padding for tablet content. Phones keep their existing
  /// value so their layout does not change.
  static double contentPadding(
    BuildContext context,
    double phoneValue, {
    double tabletValue = 32.0,
  }) {
    return isPhone(context) ? phoneValue : tabletValue;
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
    return contentMaxWidth(context);
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
  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double horizontal = 16,
    double vertical = 8,
  }) {
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
    // Cap the tablet scale-up so titles do not become disproportionately
    // large compared with the rest of the interface.
    final scaled = landscapeFontSize(context, 22) * userScale;
    return TextStyle(
      fontSize: scaled > 36 ? 36 : scaled,
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
    return Responsive.chapterTitle(
      context,
      userScale: userScale,
      fontFamily: fontFamily,
    );
  }

  static TextStyle songBody(BuildContext context, {double userScale = 1.0}) {
    return Responsive.songBody(context, userScale: userScale);
  }
}
