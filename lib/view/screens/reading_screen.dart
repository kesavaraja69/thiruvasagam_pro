// lib/views/reading_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/widgets/app_snackbars.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart'
    show CustomBannerAd;
import 'package:thiruvasagampro/view/widgets/eye_protection_overlay.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';
import 'package:thiruvasagampro/view/widgets/tts_player_widget.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';

class ReadingScreen extends StatefulWidget {
  final int chapterId;
  final bool isFromBookmarks; // 🚨 Add this new variable!
  const ReadingScreen({
    super.key,
    required this.chapterId,
    this.isFromBookmarks = false, // Defaults to false for the Home Sc
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  @override
  void initState() {
    super.initState();
    // Load the specific song when the screen opens

    Future.microtask(() {
      if (mounted) {
        Provider.of<ReadingProvider>(context, listen: false).loadBookmarks(
          widget.chapterId,
          fromBookmarks: widget.isFromBookmarks,
        );
      }
    });
  }

  @override
  void dispose() {
    // Reset chapter ad counters when navigating away (e.g. back to home)
    Provider.of<ReadingProvider>(context, listen: false)
        .resetChapterClickCounters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReadingProvider>(context);
    return ParchmentBackground(
      child: EyeProtectionOverlay(
        enabled: provider.eyeProtectionEnabled,
        warmth: provider.eyeWarmth,
        dimness: provider.eyeDimness,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Consumer<ReadingProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.vintageInk),
                );
              }

              // 🚨 2. NEW: Show a message if the database is literally empty
              if (provider.currentChapter.id == -1) {
                return const Center(
                  child: Text(
                    'தரவு கிடைக்கவில்லை. (No data found)',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              return Column(
                children: [
                  // 1. Custom Header (Title & Back/Bookmark)
                  Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: AppColors.transparent,
                      image: DecorationImage(
                        image: AssetImage(AppAssets.topBarPaper),
                        fit: BoxFit
                            .fill, // Stretches the image to fill the screen
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: _buildImageBtn(
                              AppAssets.iconBack,
                              () => Navigator.pop(context),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                left: 60,
                                right: 60,
                              ),
                              child: SizedBox(
                                width: double
                                    .infinity, // Forces it to use the available width
                                child: FittedBox(
                                  fit: BoxFit
                                      .scaleDown, // Shrinks the text automatically if it's too wide
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    provider.currentChapter.title,
                                    style: ResponsiveText.chapterTitle(
                                      context,
                                      userScale:
                                          0.9, // The starting size before any shrinking happens
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: _buildImageBtn(
                              provider.currentChapter.isBookmarked == true
                                  ? AppAssets.iconBookmarkFilled
                                  : AppAssets.iconBookmarkOutline,
                              () async {
                                await provider.toggleBookmarkWithAd(
                                  context,
                                  isFromBookmarks: widget.isFromBookmarks,
                                );
                                if (context.mounted) {
                                  AppSnackBars.showBookmark(
                                    context,
                                    isBookmarked:
                                        provider.currentChapter.isBookmarked,
                                    isFromBookmarks: widget.isFromBookmarks,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const CustomBannerAd(),
                  // 3. Action Toolbar (A-, A+, Copy, Share, Tt)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageBtn(AppAssets.iconFontDec, () async {
                          await provider.handleToolbarAction(
                            context,
                            provider.decreaseFont,
                          );
                          // provider.decreaseFont;
                        }),
                        _buildImageBtn(
                          AppAssets.iconFontInc,
                          () async {
                            await provider.handleToolbarAction(
                              context,
                              provider.increaseFont,
                            );
                          },
                          //provider.increaseFont,
                        ),
                        _buildImageBtn(
                          AppAssets.iconCopy,
                          () async {
                            await provider.handleToolbarAction(
                              context,
                              provider.copyToClipboard,
                            );
                            if (context.mounted) {
                              AppSnackBars.showBar(
                                context,
                                title: "பாடல் நகலெடுக்கப்பட்டது (Copied)",
                              );
                            }
                          },
                          // () => provider.copyToClipboard(context),
                        ),
                        _buildImageBtn(
                          AppAssets.iconShare,
                          () async {
                            await provider.handleToolbarAction(
                              context,
                              provider.shareSong,
                            );
                          },
                          // provider.shareSong
                        ),
                        _buildImageBtn(
                          AppAssets.iconFontChange,
                          () async {
                            await provider.handleToolbarAction(context, () {});
                            if (context.mounted) {
                              _showFontPicker(context, provider);
                            }
                          },
                          //() => _showFontPicker(context, provider),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 45,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Image.asset(AppAssets.topOrnament, fit: BoxFit.fill),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => provider.previousChapter(context),
                                  child: Text(
                                    '← முந்தைய',
                                    style: _navTextStyle(provider.hasPrevious),
                                  ),
                                ),
                                const Text(
                                  'பாடல்',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => provider.nextChapter(context),
                                  child: Text(
                                    'அடுத்த →',
                                    style: _navTextStyle(provider.hasNext),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Scrollable Lyrics Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        provider.currentChapter.song,
                        style: TextStyle(
                          fontSize: provider.fontSize,
                          fontFamily: provider.currentFontFamily,
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          height: 1.6, // Gives nice line spacing for Tamil text
                        ),
                      ),
                    ),
                  ),
                  
                  // 6. TTS Player Widget
                  if (provider.currentChapter.song.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: TTSPlayerWidget(
                        textToSpeak: provider.currentChapter.song,
                        title: provider.currentChapter.title,
                      ),
                    ),
                  
                  const CustomBannerAd(),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  // Helper for all those image buttons
  Widget _buildImageBtn(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          assetPath,
          width: 45,
          height: 35,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Dim the navigation text if there is no next/prev chapter
  TextStyle _navTextStyle(bool isActive) {
    return TextStyle(
      fontSize: 17,
      color: isActive ? Colors.black87 : Colors.black26,
    );
  }

  // Helper method to show the Font Selection Bottom Sheet
  void _showFontPicker(BuildContext context, ReadingProvider provider) {
    showModalBottomSheet(
      context: context,
      // Use your parchment color so it matches the app theme!
      backgroundColor: AppColors.dividerBrown,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'எழுத்துருவை மாற்று (Select Font)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 15),

                // Generate a list tile for every font we have
                ...provider.availableFonts.map((font) {
                  // Make the display name look nice
                  String displayName = font == 'System'
                      ? 'இயல்புநிலை (System)'
                      : font;

                  return ListTile(
                    title: Text(
                      'திருவாசகம் - $displayName', // Preview text in Tamil!
                      style: TextStyle(
                        // If it's 'System', leave it null. Otherwise, use the font name!
                        fontFamily: font == 'System' ? null : font,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    trailing: provider.currentFontFamily == font
                        ? const Icon(Icons.check_circle, color: AppColors.white)
                        : null,
                    onTap: () {
                      // Update the provider and close the sheet
                      provider.setFontFamily(font);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
