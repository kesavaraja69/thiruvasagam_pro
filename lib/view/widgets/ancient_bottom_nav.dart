// lib/views/widgets/ancient_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
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
    return SafeArea(
      top: false,
      child: Container(
        height: 55, // Adjust this based on how tall your torn paper image is
        width: double.infinity,
        decoration: const BoxDecoration(
          // The dark charcoal color that sits behind the torn paper edges
          color: AppColors.transparent,
          image: DecorationImage(
            image: AssetImage(AppAssets.navBarPaper),
            // 'cover' ensures the paper stretches fully across the bottom
            fit: BoxFit.fitWidth,
          ),
        ),
        // SafeArea ensures icons aren't blocked by the iPhone home indicator
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                index: 0,
                outlineIcon: AppAssets.homeOutline,
                filledIcon: AppAssets.homeFilled,
              ),
              _buildNavItem(
                index: 1,
                outlineIcon: AppAssets.bookOutline,
                filledIcon: AppAssets.bookFilled,
              ),
              _buildNavItem(
                index: 2,
                outlineIcon: AppAssets.settingsOutline,
                filledIcon: AppAssets.settingsFilled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each individual icon button
  Widget _buildNavItem({
    required int index,
    required String outlineIcon,
    required String filledIcon,
  }) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior
          .opaque, // Makes the whole area tappable, not just the visible pixels
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(
          12.0,
        ), // Adds a larger tap target for fat fingers
        child: Image.asset(
          isActive ? filledIcon : outlineIcon,
          width: 32, // Adjust size to match your design
          height: 32,
          fit: BoxFit.contain,
          // Optional: Tell Flutter to render this low-priority image efficiently
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}
