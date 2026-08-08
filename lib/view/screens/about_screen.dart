// lib/views/about_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart';
import 'package:thiruvasagampro/view/widgets/eye_protection_overlay.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Helper method to open the user's Email app
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'kesavarajamurugesan@gmail.com',
      query: 'subject=Thiruvasagam Pro App - Feedback',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
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
          child: Scaffold(
            backgroundColor: Colors.transparent,

            body: Column(
            children: [
              AntiqueHeader(title: 'எங்களை பற்றி (About)'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. App Logo & Version
                      Image.asset(AppAssets.logo1, width: 170, height: 170),
                      const SizedBox(height: 2),
                      const Text(
                        'திருவாசகம் Pro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vintageInk,
                        ),
                      ),

                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),

                      const SizedBox(height: 20),
                      Image.asset(
                        AppAssets.templeDivider,
                        height: 15,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),

                      // 2. About Thiruvasagam Section
                      const Text(
                        'திருவாசகம் பற்றி',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vintageInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10.0,
                        ),
                        child: const Text(
                          'திருவாசகம் என்பது சைவ சமயத்தின் பன்னிரு திருமுறைகளில் எட்டாம் திருமுறையாகும். இதனை ஒன்பதாம் நூற்றாண்டில் வாழ்ந்த மாணிக்கவாசகர் இயற்றினார். "திருவாசகத்திற்கு உருகார் ஒரு வாசகத்திற்கும் உருகார்" என்பது இதன் சிறப்பை உணர்த்தும் புகழ்பெற்ற பழமொழியாகும். இது சிவபெருமானின் பெருமைகளையும், பக்தியின் உச்சத்தையும் எடுத்துரைக்கிறது.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const CustomBannerAd(),
                      const SizedBox(height: 20),
                      Image.asset(
                        AppAssets.templeDivider,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),

                      // 3. The Dedication Section (Your Mother's Story)
                      const Text(
                        'சமர்ப்பணம் (Dedication)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vintageInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10.0,
                        ),
                        child: const Text(
                          'இந்தச் செயலி எனது அன்பான தாயாருக்குச் சமர்ப்பணம். அவர் தீவிர ஆன்மீகவாதி மற்றும் திருவாசகத்தை ஆழமாக நேசிப்பவர். அவரின் இந்த பக்திதான், அனைவரையும் எளிதில் சென்றடையும் வகையில் இந்த செயலியை உருவாக்க எனக்கு உந்துதலாக அமைந்தது.\n\nThis app is lovingly dedicated to my mother, a deeply spiritual soul whose boundless love for the Thiruvasagam inspired its creation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle
                                .italic, // Adds a nice touch to the dedication
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        AppAssets.templeDivider,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),

                      // 4. Contact / Feedback Section
                      Container(
                        padding: const EdgeInsets.all(20),

                        child: Column(
                          children: [
                            const Text(
                              'உங்கள் கருத்துக்கள் (Feedback)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.vintageInk,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'இந்த செயலியில் ஏதேனும் மாற்றங்கள் அல்லது திருத்தங்கள் செய்ய விரும்பினால், தயங்காமல் என்னை தொடர்பு கொள்ளவும்.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // The Contact Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.vintageInk,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.mail_outline),
                              label: const Text(
                                'Contact Us',
                                style: TextStyle(fontSize: 16),
                              ),
                              onPressed: _launchEmail,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 40,
                      ), // Bottom padding so it scrolls nicely
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
