// lib/views/widgets/ancient_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import '../../utils/app_assets.dart';

class AncientBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AncientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Compact bottom nav in landscape on tablets to save vertical space
    final navHeight = Responsive.isTabletLandscape(context)
        ? Responsive.compactHeight(context, 50)
        : Responsive.height(context, 50);
    final iconSize = Responsive.isTabletLandscape(context)
        ? Responsive.dim(context, 22)
        : Responsive.dim(context, 28);

    return SafeArea(
      top: false,
      child: Container(
        height: navHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.transparent,
          image: DecorationImage(
            image: AssetImage(AppAssets.navBarPaper),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                outlineIcon: AppAssets.homeOutline,
                filledIcon: AppAssets.homeFilled,
                iconSize: iconSize,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                outlineIcon: AppAssets.bookOutline,
                filledIcon: AppAssets.bookFilled,
                iconSize: iconSize,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                outlineIcon: AppAssets.settingsOutline,
                filledIcon: AppAssets.settingsFilled,
                iconSize: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each individual icon button
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String outlineIcon,
    required String filledIcon,
    double? iconSize,
  }) {
    final bool isActive = currentIndex == index;
    final size = iconSize ?? Responsive.dim(context, 28);
    final padding = Responsive.isTabletLandscape(context)
        ? Responsive.padding(context, 6)
        : Responsive.padding(context, 10);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          isActive ? filledIcon : outlineIcon,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}
