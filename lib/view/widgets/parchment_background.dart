import 'package:flutter/material.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';

class ParchmentBackground extends StatelessWidget {
  final Widget child;
  // This allows you to set a default background, but swap it out if you ever need to!
  final String imagePath;

  const ParchmentBackground({
    super.key,
    required this.child,

    this.imagePath = AppAssets.parchmentBg,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.fill, // Stretches the image to fill the screen
            // Optional: If your background image is too bright and makes the text
            // hard to read, uncomment these lines to add a subtle dark tint.
            // colorFilter: ColorFilter.mode(
            //   Colors.black.withOpacity(0.05),
            //   BlendMode.darken,
            // ),
          ),
        ),
        child: child,
      ),
    );
  }
}
