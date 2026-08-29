// lib/utils/app_snackbars.dart

import 'package:flutter/material.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';

class AppSnackBars {
  static void showBookmark(
    BuildContext context, {
    required bool isBookmarked,
    required bool isFromBookmarks,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFromBookmarks == true
              ? 'நீக்கப்பட்டது (Removed)'
              : isBookmarked == true
              ? 'புக்மார்க்கில் சேர்க்கப்பட்டது (Added)'
              : 'நீக்கப்பட்டது (Removed)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.vintageInk,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: Responsive.padding(context, 20),
          left: Responsive.padding(context, 20),
          right: Responsive.padding(context, 20),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
        ),
      ),
    );
  }

  static void showBar(BuildContext context, {required String title}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.vintageInk,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: Responsive.padding(context, 20),
          left: Responsive.padding(context, 20),
          right: Responsive.padding(context, 20),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
        ),
      ),
    );
  }
}
