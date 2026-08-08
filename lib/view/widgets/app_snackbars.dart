// lib/utils/app_snackbars.dart

import 'package:flutter/material.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
// Make sure this path is correct

class AppSnackBars {
  static void showBookmark(
    BuildContext context, {
    required bool isBookmarked,
    required bool isFromBookmarks,
  }) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show the new one
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFromBookmarks == true
              ? 'நீக்கப்பட்டது (Removed)'
              : isBookmarked == true
              ? 'புக்மார்க்கில் சேர்க்கப்பட்டது (Added)'
              : 'நீக்கப்பட்டது (Removed)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.vintageInk,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void showBar(BuildContext context, {required String title}) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show the new one
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.vintageInk,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
