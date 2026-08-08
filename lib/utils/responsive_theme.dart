import 'package:flutter/material.dart';

class ResponsiveText {
  static double getScaleFactor(BuildContext context) {
    // 375 is a standard mobile screen width (e.g., iPhone SE/mini)
    double screenWidth = MediaQuery.of(context).size.width;

    // Cap the scaling for iPads so text doesn't become comically huge
    if (screenWidth > 600) {
      screenWidth = 600;
    }
    return screenWidth / 375.0;
  }

  // Reusable TextStyles
  static TextStyle chapterTitle(
    BuildContext context, {
    double userScale = 1.0,
    String fontFamily = '',
  }) {
    return TextStyle(
      fontSize: 22 * getScaleFactor(context) * userScale,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF4A0E00), // Dark brown/maroon ink color
      fontFamily: fontFamily,
    );
  }

  static TextStyle songBody(BuildContext context, {double userScale = 1.0}) {
    return TextStyle(
      fontSize: 18 * getScaleFactor(context) * userScale,
      height: 1.6, // Good line height for reading poetry
      color: const Color(0xFF2C1A0B), // Dark ink color
      // fontFamily: 'YourTamilFontHere',
    );
  }
}
