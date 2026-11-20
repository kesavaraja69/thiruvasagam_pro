// lib/views/widgets/antique_header.dart

import 'dart:math' as math;

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
    // Tablets get a fixed, comfortable header height instead of stretching the
    // paper strip to well over 100px. Landscape tablets stay compact so the
    // content below keeps most of the limited vertical space.
    final headerHeight = Responsive.isTabletLandscape(context)
        ? 64.0
        : math.min(Responsive.height(context, height), 112.0);

    // Keep the title away from the torn edges and never let a long title
    // overflow: FittedBox shrinks it instead of painting outside the header.
    final horizontalPadding = Responsive.isPhone(context)
        ? Responsive.padding(context, 24)
        : 64.0;

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: const BoxDecoration(
        color: AppColors.transparent,
        image: DecorationImage(
          image: AssetImage(AppAssets.topBarPaper),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: Responsive.isTabletLandscape(context)
              ? 8
              : Responsive.padding(context, 5),
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: Text(
              title,
              style: ResponsiveText.chapterTitle(
                context,
                userScale: userScale,
                fontFamily: fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
