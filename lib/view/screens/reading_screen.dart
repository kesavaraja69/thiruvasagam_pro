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
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/view/widgets/parchment_background.dart';
import 'package:thiruvasagampro/view/widgets/reward_ad_prompt.dart';
import 'package:thiruvasagampro/view/widgets/tts_player_widget.dart';
import 'package:thiruvasagampro/view/widgets/audio_player_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
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
  ReadingProvider? _readingProvider;
  bool _isAudioAvailable = false;
  bool _isCheckingAudio = true;
  int? _lastCheckedChapterId;

  /// True while we are switching songs because the previous one finished.
  /// The next [AudioPlayerWidget] reads this and starts playing on its own.
  bool _autoPlayNext = false;

  @override
  void initState() {
    super.initState();
    _lastCheckedChapterId = widget.chapterId;
    Future.microtask(() {
      if (mounted) {
        Provider.of<ReadingProvider>(context, listen: false).loadBookmarks(
          widget.chapterId,
          fromBookmarks: widget.isFromBookmarks,
        );
      }
    });
    _checkAudioAvailability(widget.chapterId);
  }

  Future<void> _checkAudioAvailability(int? chapterId) async {
    if (!mounted) return;

    setState(() {
      _isCheckingAudio = true;
    });

    if (chapterId == null || chapterId == -1) {
      if (mounted) {
        setState(() {
          _isAudioAvailable = false;
          _isCheckingAudio = false;
        });
        _releaseAutoPlayNext();
      }
      return;
    }

    final audioUrl = 'https://thiruvasagam.dftacademy.in/song$chapterId.mp3';

    // Check connectivity
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isEmpty ||
          connectivityResults.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            _isAudioAvailable = false;
            _isCheckingAudio = false;
          });
          _releaseAutoPlayNext();
        }
        return;
      }
    } catch (_) {}

    // HEAD request to verify URL
    try {
      final response = await http.head(Uri.parse(audioUrl));
      if (mounted) {
        setState(() {
          _isAudioAvailable = response.statusCode == 200;
          _isCheckingAudio = false;
        });
        _releaseAutoPlayNext();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAudioAvailable = false;
          _isCheckingAudio = false;
        });
        _releaseAutoPlayNext();
      }
    }
  }

  /// Called when a song reaches its end: jump to the next song and play it
  /// automatically so the reader can keep listening without tapping play.
  void _handleAudioCompleted() {
    if (!mounted) return;
    final provider = Provider.of<ReadingProvider>(context, listen: false);

    // Nothing to continue with, or the user turned Continuous Play off.
    if (!provider.hasNext || !provider.continuousPlayEnabled) {
      setState(() => _autoPlayNext = false);
      return;
    }

    setState(() {
      _autoPlayNext = true;
      _isCheckingAudio = true;
    });

    // No interstitial here — auto playback should stay uninterrupted.
    provider.autoAdvanceChapter();
  }

  /// Clears the auto-play flag *after* the rebuilt (auto-playing) player has
  /// mounted, so it only applies to the song we just switched to.
  void _releaseAutoPlayNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _autoPlayNext) {
        setState(() => _autoPlayNext = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ReadingProvider>(context);
    _readingProvider = provider;
    final currentChapterId = provider.currentChapter.id;
    if (currentChapterId != null &&
        currentChapterId != -1 &&
        currentChapterId != _lastCheckedChapterId) {
      _lastCheckedChapterId = currentChapterId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAudioAvailability(currentChapterId);
      });
    }
  }

  @override
  void dispose() {
    // Reset chapter ad counters when navigating away (e.g. back to home).
    // Use the cached provider: looking it up here would read a deactivated
    // element and throw during unmount.
    _readingProvider?.resetChapterClickCounters();
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
                    child: CircularProgressIndicator(
                      color: AppColors.vintageInk,
                    ),
                  );
                }

                // 🚨 2. NEW: Show a message if the database is literally empty
                if (provider.currentChapter.id == -1) {
                  return Center(
                    child: Text(
                      'தரவு கிடைக்கவில்லை. (No data found)',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 18),
                      ),
                    ),
                  );
                }

                final isLandscape = Responsive.isTabletLandscape(context);

                // ── Landscape tablet layout ──────────────────────
                if (isLandscape) {
                  return _buildLandscapeLayout(context, provider);
                }

                // ── Portrait layout (phones + portrait tablets) ──
                return Column(
                  children: [
                    // 1. Custom Header (Title & Back/Bookmark)
                    Container(
                      height: Responsive.height(context, 60),
                      decoration: BoxDecoration(
                        color: AppColors.transparent,
                        image: DecorationImage(
                          image: AssetImage(AppAssets.topBarPaper),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 2),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: _buildImageBtntb(
                                AppAssets.iconBack,
                                () => Navigator.pop(context),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: Responsive.padding(context, 12),
                                  left: Responsive.padding(context, 50),
                                  right: Responsive.padding(context, 50),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      provider.currentChapter.title,
                                      style: ResponsiveText.chapterTitle(
                                        context,
                                        userScale: 0.9,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildImageBtntb(
                                provider.currentChapter.isBookmarked == true
                                    ? AppAssets.iconBookmarkFilled
                                    : AppAssets.iconBookmarkOutline,
                                () async {
                                  provider.toggleBookmark(
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
                    // 3. Action Toolbar (A-, A+, Copy, Share, Tt)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.padding(context, 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildImageBtn(AppAssets.iconFontDec, () {
                            provider.decreaseFont();
                          }),
                          _buildImageBtn(AppAssets.iconFontInc, () {
                            provider.increaseFont();
                          }),
                          _buildImageBtn(AppAssets.iconCopy, () {
                            provider.copyToClipboard();
                            if (context.mounted) {
                              AppSnackBars.showBar(
                                context,
                                title: "பாடல் நகலெடுக்கப்பட்டது (Copied)",
                              );
                            }
                          }),
                          _buildImageBtn(AppAssets.iconShare, () {
                            provider.shareSong();
                          }),
                          _buildImageBtn(AppAssets.iconFontChange, () {
                            _showFontPicker(context, provider);
                          }),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.padding(context, 12),
                      ),
                      child: SizedBox(
                        height: Responsive.height(context, 35),
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Image.asset(
                              AppAssets.topOrnament,
                              fit: BoxFit.fill,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.padding(context, 20),
                                vertical: Responsive.padding(context, 8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        provider.previousChapter(context),
                                    child: Text(
                                      '← முந்தைய',
                                      style: _navTextStyle(
                                        provider.hasPrevious,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'பாடல் ${provider.currentChapter.id ?? widget.chapterId}/51',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.fontSize(
                                        context,
                                        15,
                                      ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 20),
                        ),
                        child: Text(
                          provider.currentChapter.song,
                          style: TextStyle(
                            fontSize: provider.fontSize,
                            fontFamily: provider.currentFontFamily,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),

                    // 6. Audio Players Section
                    if (provider.currentChapter.song.isNotEmpty)
                      Container(
                        padding: EdgeInsets.only(
                          top: Responsive.padding(context, 8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isCheckingAudio)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.padding(context, 12),
                                  vertical: Responsive.padding(context, 4),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    Responsive.padding(context, 12),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.dividerBrown.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Responsive.radius(context, 16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: Responsive.dim(context, 16),
                                        height: Responsive.dim(context, 16),
                                        child: CircularProgressIndicator(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.padding(context, 8),
                                      ),
                                      Text(
                                        'Checking audio...',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: Responsive.fontSize(
                                            context,
                                            12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_isAudioAvailable)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.padding(context, 12),
                                  vertical: Responsive.padding(context, 4),
                                ),
                                child: AudioPlayerWidget(
                                  audioUrl: provider.currentChapter.id != null
                                      ? 'https://thiruvasagam.dftacademy.in/song${provider.currentChapter.id}.mp3'
                                      : null,
                                  chapterId: provider.currentChapter.id,
                                  title: provider.currentChapter.title,
                                  autoPlay: _autoPlayNext,
                                  onCompleted: _handleAudioCompleted,
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.padding(context, 12),
                                  vertical: Responsive.padding(context, 4),
                                ),
                                child: TTSPlayerWidget(
                                  textToSpeak: provider.currentChapter.song,
                                  title: provider.currentChapter.title,
                                ),
                              ),
                          ],
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

  // ── Landscape tablet layout ──────────────────────────────────────
  // Compact header + toolbar row, navigation inline, wider centered text
  Widget _buildLandscapeLayout(BuildContext context, ReadingProvider provider) {
    return Column(
      children: [
        // Compact header bar with back, title, bookmark all in one row
        Container(
          height: Responsive.compactHeight(context, 60),
          decoration: const BoxDecoration(
            color: AppColors.transparent,
            image: DecorationImage(
              image: AssetImage(AppAssets.topBarPaper),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 8),
            ),
            child: Row(
              children: [
                // Back button
                _buildImageBtntb(
                  AppAssets.iconBack,
                  () => Navigator.pop(context),
                ),
                // Title (expanded)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.padding(context, 4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        provider.currentChapter.title,
                        style: ResponsiveText.chapterTitle(
                          context,
                          userScale: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bookmark button
                _buildImageBtntb(
                  provider.currentChapter.isBookmarked == true
                      ? AppAssets.iconBookmarkFilled
                      : AppAssets.iconBookmarkOutline,
                  () async {
                    provider.toggleBookmark(
                      isFromBookmarks: widget.isFromBookmarks,
                    );
                    if (context.mounted) {
                      AppSnackBars.showBookmark(
                        context,
                        isBookmarked: provider.currentChapter.isBookmarked,
                        isFromBookmarks: widget.isFromBookmarks,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Toolbar + Navigation in a single compact row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 12),
          ),
          child: SizedBox(
            height: Responsive.compactHeight(context, 35),
            child: Row(
              children: [
                // Prev chapter
                GestureDetector(
                  onTap: () => provider.previousChapter(context),
                  child: Text(
                    '← முந்தைய',
                    style: _navTextStyle(provider.hasPrevious),
                  ),
                ),
                // Toolbar buttons
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageBtn(AppAssets.iconFontDec, () {
                        provider.decreaseFont();
                      }),
                      _buildImageBtn(AppAssets.iconFontInc, () {
                        provider.increaseFont();
                      }),
                      _buildImageBtn(AppAssets.iconCopy, () {
                        provider.copyToClipboard();
                        if (context.mounted) {
                          AppSnackBars.showBar(
                            context,
                            title: "பாடல் நகலெடுக்கப்பட்டது (Copied)",
                          );
                        }
                      }),
                      _buildImageBtn(AppAssets.iconShare, () {
                        provider.shareSong();
                      }),
                      _buildImageBtn(AppAssets.iconFontChange, () {
                        _showFontPicker(context, provider);
                      }),
                    ],
                  ),
                ),
                // Song counter
                Text(
                  '${provider.currentChapter.id ?? widget.chapterId}/51',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 13),
                  ),
                ),
                // Next chapter
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
        ),

        // Scrollable lyrics content — wider in landscape, centered with max width
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.readingMaxWidth(context),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context, 24),
                  vertical: Responsive.padding(context, 8),
                ),
                child: Text(
                  provider.currentChapter.song,
                  style: TextStyle(
                    fontSize: provider.fontSize,
                    fontFamily: provider.currentFontFamily,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Audio player — compact in landscape
        if (provider.currentChapter.song.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 12),
            ),
            child: _isCheckingAudio
                ? Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 6)),
                    child: Text(
                      'Checking audio...',
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: Responsive.fontSize(context, 11),
                      ),
                    ),
                  )
                : _isAudioAvailable
                ? AudioPlayerWidget(
                    audioUrl: provider.currentChapter.id != null
                        ? 'https://thiruvasagam.dftacademy.in/song${provider.currentChapter.id}.mp3'
                        : null,
                    chapterId: provider.currentChapter.id,
                    title: provider.currentChapter.title,
                    autoPlay: _autoPlayNext,
                    onCompleted: _handleAudioCompleted,
                  )
                : TTSPlayerWidget(
                    textToSpeak: provider.currentChapter.song,
                    title: provider.currentChapter.title,
                  ),
          ),

        const CustomBannerAd(),
      ],
    );
  }

  // Helper for all those image buttons
  Widget _buildImageBtn(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 6)),
        child: Image.asset(
          assetPath,
          width: Responsive.dim(context, 30),
          height: Responsive.dim(context, 30),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildImageBtntb(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 6)),
        child: Image.asset(
          assetPath,
          width: Responsive.dim(context, 38),
          height: Responsive.dim(context, 38),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Dim the navigation text if there is no next/prev chapter
  TextStyle _navTextStyle(bool isActive) {
    return TextStyle(
      fontSize: Responsive.fontSize(context, 15),
      color: isActive ? Colors.black87 : Colors.black26,
    );
  }

  // Helper method to show the Font Selection Bottom Sheet
  void _showFontPicker(BuildContext context, ReadingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dividerBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.radius(context, 20)),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.padding(context, 20),
            horizontal: Responsive.padding(context, 16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'எழுத்துருவை மாற்று (Select Font)',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: Responsive.height(context, 15)),
                ...provider.availableFonts.map((font) {
                  String displayName = font == 'System'
                      ? 'இயல்புநிலை (System)'
                      : font;
                  final isLocked =
                      !ReadingProvider.freeFonts.contains(font) &&
                      !provider.fontsUnlocked;
                  return ListTile(
                    title: Text(
                      'திருவாசகம் - $displayName',
                      style: TextStyle(
                        fontFamily: font == 'System' ? null : font,
                        fontSize: Responsive.fontSize(context, 16),
                        color: Colors.white,
                      ),
                    ),
                    subtitle: isLocked
                        ? Text(
                            '24 மணி நேரத்திற்கு விளம்பரம் பார்த்து திறக்க',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 11),
                              color: Colors.white70,
                            ),
                          )
                        : null,
                    trailing: isLocked
                        ? Icon(
                            Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.7),
                          )
                        : provider.currentFontFamily == font
                        ? Icon(Icons.check_circle, color: AppColors.white)
                        : null,
                    onTap: () async {
                      if (isLocked) {
                        final earned = await showRewardedAdPrompt(
                          context,
                          title: 'பிரீமியம் எழுத்துரு',
                          description:
                              'இந்த எழுத்துருவை 24 மணி நேரத்திற்கு திறக்க ஒரு குறுகிய விளம்பரத்தைப் பாருங்கள்.',
                        );
                        if (!earned || !context.mounted) return;
                        await RewardUnlockService.instance.grantFonts();
                        if (!context.mounted) return;
                      }
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
