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
    final isPhone = Responsive.isPhone(context);
    final isLandscapeTablet = Responsive.isTabletLandscape(context);

    // A fixed, usable height on tablets. Deriving it from the compact height
    // used to leave the icons larger than the bar itself in landscape.
    final navHeight = isPhone
        ? Responsive.height(context, 50)
        : (isLandscapeTablet ? 56.0 : 64.0);
    final iconSize = isPhone
        ? Responsive.dim(context, 28)
        : (isLandscapeTablet ? 30.0 : 34.0);

    final navItems = Row(
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
    );

    return SafeArea(
      top: false,
      child: Container(
        height: navHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.transparent,
          image: DecorationImage(
            image: AssetImage(AppAssets.navBarPaper),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            // Keep the three icons grouped on tablets instead of spreading
            // them across the full width of a 10" screen.
            constraints: BoxConstraints(maxWidth: isPhone ? 520 : 560),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, isPhone ? 20 : 8),
              ),
              child: navItems,
            ),
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
    final padding = Responsive.isPhone(context)
        ? Responsive.padding(context, 10)
        : 14.0;

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
