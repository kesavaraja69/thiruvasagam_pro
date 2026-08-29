// lib/views/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';

import 'main_wrapper.dart'; // Or wherever your HomeScreen/BottomNav is

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // The Data for the 3 screens
  final List<Map<String, String>> _pages = [
    {
      'image': AppAssets.logo1,
      'title': 'திருவாசகம் புரோ-வுக்கு\nவரவேற்கிறோம்',
      'body':
          'மாணிக்கவாசகரின் தெய்வீகப் பாடல்களை ஆழமாகப் படித்து அனுபவியுங்கள்.',
    },
    {
      'image': AppAssets.logo1,
      'title': 'வாசிப்பு அனுபவத்தைத்\nதனிப்பயனாக்குங்கள்',
      'body':
          'எழுத்து அளவு மற்றும் பாணியை உங்கள் விருப்பத்திற்கேற்ப மாற்றிக் கொள்ளுங்கள். எளிதாக பகிருங்கள் மற்றும் நகலெடுங்கள்.',
    },
    {
      'image': AppAssets.logo1,
      'title': 'பிடித்தமான பாடல்களைச்\nசேமித்து வையுங்கள்',
      'body':
          'எளிதான புக்மார்க் வசதியுடன் உங்கள் தனிப்பட்ட சேகரிப்பை உருவாக்குங்கள்.',
    },
  ];

  // 🚨 This function saves the "first time" status so it never shows again!
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    // Navigate to the main app and remove the onboarding from the backstack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  void _onboardingAction() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentBackground(
      imagePath: AppAssets.parchmentBg1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageView.builder(
          controller: _controller,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            final isLandscape = Responsive.isTabletLandscape(context);

            // ── Content text widget (reused in both layouts) ──
            final textContent = SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: isLandscape ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Text(
                    _pages[index]['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 19),
                      fontWeight: FontWeight.bold,
                      color: AppColors.vintageInk,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: Responsive.height(context, 12)),
                  Text(
                    _pages[index]['body']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: Responsive.height(context, 12)),
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 5),
                        ),
                        height: Responsive.dim(context, 10),
                        width: _currentPage == i
                            ? Responsive.dim(context, 20)
                            : Responsive.dim(context, 10),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.vintageInk
                              : AppColors.vintageInk.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            Responsive.radius(context, 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, isLandscape ? 40 : 30),
              ),
              child: isLandscape
                  // ── Landscape: image left, text right ──
                  ? Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Image.asset(
                              _pages[index]['image']!,
                              height: Responsive.height(context, 160),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.padding(context, 24)),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              textContent,
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: Responsive.height(context, 44),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.vintageInk,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Responsive.radius(context, 10),
                                      ),
                                    ),
                                  ),
                                  onPressed: _onboardingAction,
                                  child: Text(
                                    _currentPage == _pages.length - 1
                                        ? 'தொடங்குங்கள் (Get Started)'
                                        : 'அடுத்து (Next)',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        14,
                                      ),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  // ── Portrait: stacked vertically ──
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Image.asset(
                            _pages[index]['image']!,
                            height: Responsive.height(context, 160),
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: Responsive.height(context, 6)),
                          textContent,
                          SizedBox(height: Responsive.height(context, 25)),
                          SizedBox(
                            width: double.infinity,
                            height: Responsive.height(context, 50),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.vintageInk,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.radius(context, 10),
                                  ),
                                ),
                              ),
                              onPressed: _onboardingAction,
                              child: Text(
                                _currentPage == _pages.length - 1
                                    ? 'தொடங்குங்கள் (Get Started)'
                                    : 'அடுத்து (Next)',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 15),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
