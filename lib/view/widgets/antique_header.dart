// lib/views/widgets/antique_header.dart

import 'package:flutter/material.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_theme.dart'; // Make sure this path is correct!

class AntiqueHeader extends StatelessWidget {
  final String title;
  final String fontFamily;
  final double height;
  final double userScale;

  const AntiqueHeader({
    super.key,
    required this.title,
    // 🚨 DEFAULT FONT SET HERE:
    this.fontFamily = 'Kavivanar',
    this.height = 80.0,
    this.userScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.transparent,
        image: DecorationImage(
          image: AssetImage(AppAssets.topBarPaper),
          // Changed to 'cover' so the paper texture never looks stretched or squished
          fit: BoxFit.fill,
        ),
      ),
      // Cleaned up the unnecessary Stack widget!
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: ResponsiveText.chapterTitle(
              context,
              userScale: userScale,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}
