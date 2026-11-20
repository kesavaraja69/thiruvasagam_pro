// lib/views/splash_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';

import 'onboarding_screen.dart';
import 'main_wrapper.dart'; // Your main app screen with Bottom Navigation

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // 2. Create a Future that specifically awaits the image caching
  Future<void> _cacheImages(BuildContext context) async {
    // The 'await' here is the magic word. It stops the clock until the image is ready.
    await Future.wait([
      precacheImage(const AssetImage(AppAssets.parchmentBg), context),
      precacheImage(const AssetImage(AppAssets.navBarPaper), context),
      precacheImage(const AssetImage(AppAssets.topBarPaper), context),
    ]);
  }

  Future<void> _initializeApp() async {
    FlutterNativeSplash.remove();
    // 1. Force the splash screen to stay visible for at least 2.5 seconds
    // (This gives time for the database to load AND lets the user see the logo)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    await _cacheImages(context);
    // 2. Check if the user has seen the onboarding tutorial
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;
    // 3. Navigate with a smooth fade transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSeenOnboarding ? const MainWrapper() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final logoSize = math.min(
      Responsive.dim(context, 300),
      math.min(screen.width * 0.62, screen.height * 0.45),
    );

    return ParchmentBackground(
      imagePath: AppAssets.parchmentBg1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Sacred Logo
              Image.asset(
                AppAssets.logo2,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),

              SizedBox(height: Responsive.height(context, 20)),

              // 2. App Title in Tamil

              // // 3. Custom Loading Indicator matching your theme
              // const CircularProgressIndicator(
              //   valueColor: AlwaysStoppedAnimation<Color>(AppColors.vintageInk),
              //   strokeWidth: 3.0,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
