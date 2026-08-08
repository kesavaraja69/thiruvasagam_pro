// lib/views/main_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/view/screens/bookmark_screen.dart';
import 'package:thiruvasagampro/view/screens/settings_screen.dart';
import 'package:thiruvasagampro/view/widgets/ancient_bottom_nav.dart';
import 'package:thiruvasagampro/view/widgets/eye_protection_overlay.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';

import 'home_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // The list of screens to show based on the selected tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarkScreen(), // Placeholder
    // Placeholder
    const SettingsScreen(), // Placeholder
  ];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReadingProvider>(context);

    return ParchmentBackground(
      child: EyeProtectionOverlay(
        enabled: provider.eyeProtectionEnabled,
        warmth: provider.eyeWarmth,
        dimness: provider.eyeDimness,
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            backgroundColor: AppColors.transparent,
            extendBody: true,

            body: IndexedStack(index: _selectedIndex, children: _screens),

            bottomNavigationBar: AncientBottomNav(
              currentIndex: _selectedIndex,
              onTap: _onNavTapped,
            ),
          ),
        ),
      ),
    );
  }
}
