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
    // In landscape on tablets, use a compact header to save vertical space
    final headerHeight = Responsive.isTabletLandscape(context)
        ? Responsive.compactHeight(context, height)
        : Responsive.height(context, height);

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
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: Responsive.padding(context, 5)),
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
    );
  }
}
