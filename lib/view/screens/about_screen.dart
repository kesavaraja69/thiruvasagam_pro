// lib/views/about_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
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
    AppOpenAdManager.skipNextResume();
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.readingMaxWidth(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. App Logo & Version
                            Image.asset(
                              AppAssets.logo1,
                              width: Responsive.isTabletLandscape(context)
                                  ? Responsive.dim(context, 90)
                                  : Responsive.dim(context, 150),
                              height: Responsive.isTabletLandscape(context)
                                  ? Responsive.dim(context, 90)
                                  : Responsive.dim(context, 150),
                            ),
                            SizedBox(height: Responsive.height(context, 2)),
                            Text(
                              'திருவாசகம் Pro',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 26),
                                fontWeight: FontWeight.bold,
                                color: AppColors.vintageInk,
                              ),
                            ),
                            // Reads the version from pubspec at runtime so it
                            // never drifts from the shipped build.
                            _AppVersionText(
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 13),
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: Responsive.height(context, 20)),
                            Image.asset(
                              AppAssets.templeDivider,
                              height: Responsive.dim(context, 13),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: Responsive.height(context, 20)),

                            // 2. About Thiruvasagam Section
                            Text(
                              'திருவாசகம் பற்றி',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.vintageInk,
                              ),
                            ),
                            SizedBox(height: Responsive.height(context, 10)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.padding(context, 24),
                                vertical: Responsive.padding(context, 10),
                              ),
                              child: Text(
                                'திருவாசகம் என்பது சைவ சமயத்தின் பன்னிரு திருமுறைகளில் எட்டாம் திருமுறையாகும். இதனை ஒன்பதாம் நூற்றாண்டில் வாழ்ந்த மாணிக்கவாசகர் இயற்றினார். "திருவாசகத்திற்கு உருகார் ஒரு வாசகத்திற்கும் உருகார்" என்பது இதன் சிறப்பை உணர்த்தும் புகழ்பெற்ற பழமொழியாகும். இது சிவபெருமானின் பெருமைகளையும், பக்தியின் உச்சத்தையும் எடுத்துரைக்கிறது.',
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 15),
                                  color: Colors.black87,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const CustomBannerAd(),
                            SizedBox(height: Responsive.height(context, 20)),
                            Image.asset(
                              AppAssets.templeDivider,
                              height: Responsive.dim(context, 15),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: Responsive.height(context, 20)),

                            // 3. The Dedication Section
                            Text(
                              'சமர்ப்பணம் (Dedication)',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.vintageInk,
                              ),
                            ),
                            SizedBox(height: Responsive.height(context, 10)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.padding(context, 24),
                                vertical: Responsive.padding(context, 10),
                              ),
                              child: Text(
                                'இந்தச் செயலி எனது அன்பான தாயாருக்குச் சமர்ப்பணம். அவர் தீவிர ஆன்மீகவாதி மற்றும் திருவாசகத்தை ஆழமாக நேசிப்பவர். அவரின் இந்த பக்திதான், அனைவரையும் எளிதில் சென்றடையும் வகையில் இந்த செயலியை உருவாக்க எனக்கு உந்துதலாக அமைந்தது.\n\nThis app is lovingly dedicated to my mother, a deeply spiritual soul whose boundless love for the Thiruvasagam inspired its creation. நன்றியும் அன்பும்\n\nதிருச்சி பொறியாளர் சிவ சந்திரசேகரன் அவர்களுக்கு எங்களது மனமார்ந்த நன்றியைத் தெரிவித்துக் கொள்கிறோம். அவர்கள் தங்களது இனிய குரலில் பாடிய திருவாசகப் பாடல்களை, அவர்களின் அன்பான அனுமதியுடன் திருவாசகம் Pro செயலியில் சேர்க்கும் வாய்ப்பை வழங்கியதற்கு மிக்க நன்றி.\n\nThank You\n\nOur heartfelt thanks to திருச்சி பொறியாளர் சிவ சந்திரசேகரன் for graciously giving us permission to include the Thiruvasagam songs sung in his voice in the Thiruvasagam Pro app.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                  color: Colors.black87,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(height: Responsive.height(context, 20)),
                            Image.asset(
                              AppAssets.templeDivider,
                              height: Responsive.dim(context, 15),
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: Responsive.height(context, 20)),

                            // 4. Contact / Feedback Section
                            Padding(
                              padding: EdgeInsets.all(
                                Responsive.padding(context, 20),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'உங்கள் கருத்துக்கள் (Feedback)',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        17,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.vintageInk,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.height(context, 10),
                                  ),
                                  Text(
                                    'இந்த செயலியில் ஏதேனும் மாற்றங்கள் அல்லது திருத்தங்கள் செய்ய விரும்பினால், தயங்காமல் என்னை தொடர்பு கொள்ளவும்.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        14,
                                      ),
                                      color: Colors.black87,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.height(context, 15),
                                  ),

                                  // The Contact Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.vintageInk,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Responsive.padding(
                                          context,
                                          20,
                                        ),
                                        vertical: Responsive.padding(
                                          context,
                                          12,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.radius(context, 10),
                                        ),
                                      ),
                                    ),
                                    icon: Icon(Icons.mail_outline),
                                    label: Text(
                                      'Contact Us',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(
                                          context,
                                          15,
                                        ),
                                      ),
                                    ),
                                    onPressed: _launchEmail,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: Responsive.height(context, 40)),
                          ],
                        ),
                      ),
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

/// Shows the installed app version (pubspec `version:`), e.g. "Version 1.10.0".
class _AppVersionText extends StatefulWidget {
  const _AppVersionText({required this.style});

  final TextStyle style;

  @override
  State<_AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<_AppVersionText> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (!mounted) return;
          setState(() => _version = info.version);
        })
        .catchError((Object error) {
          debugPrint('Could not read app version: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_version == null) return const SizedBox.shrink();
    return Text('Version $_version', style: widget.style);
  }
}
