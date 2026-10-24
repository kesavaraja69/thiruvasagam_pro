import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiruvasagampro/services/notification_service.dart';
import 'package:thiruvasagampro/services/reading_progress_service.dart';
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/utils/ad_consent_manager.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';
import '../models/chapter.dart';
import '../services/database_service.dart';
import 'package:share_plus/share_plus.dart';

class ReadingProvider with ChangeNotifier {
  List<Chapter> _chapters = [];
  bool _isLoadingm = true;

  List<Chapter> get chapters => _chapters;
  bool get isLoadingm => _isLoadingm;

  //

  List<Chapter> _allChapters = [];
  int _currentIndex = 0;

  // bookmark
  // 1. Add this new variable at the top with your other variables:
  List<Chapter> _bookmarkedChapters = [];
  List<Chapter> get bookmarkedChapters => _bookmarkedChapters;

  bool _isReadingFromBookmarks = false;

  // Eye Protection / Read Mode Settings
  bool _eyeProtectionEnabled = false;
  double _eyeWarmth = 0.3;
  double _eyeDimness = 0.15;

  bool get eyeProtectionEnabled =>
      _eyeProtectionEnabled &&
      RewardUnlockService.instance.eyeProtectionEnabled;
  double get eyeWarmth => _eyeWarmth;
  double get eyeDimness => _eyeDimness;

  // Continuous Play (auto-advance to the next song when one finishes)
  bool _continuousPlayEnabled = true;

  bool get continuousPlayEnabled => _continuousPlayEnabled;

  // Daily reminder notification (defaults to 6:00 PM)
  bool _reminderEnabled = true;
  int _reminderHour = 18;
  int _reminderMinute = 0;

  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  // Font Settings
  double _fontSize = 19.0;
  int _fontIndex = 0;

  // 1. Define the fonts we just added to pubspec.yaml
  // 'System' uses the default phone font.
  final List<String> _fontFamilies = [
    'System',
    'NotoSansTamil',
    'TiroTamil',
    'Arima',
    'HindMadurai',
    'Pavanam',
    'Kavivanar',
  ];

  String _currentFontFamily = 'System'; // Default font

  /// Fonts available without watching a rewarded ad.
  static const Set<String> freeFonts = {'System', 'NotoSansTamil'};

  // 2. Add Getters
  String get currentFontFamily {
    if (!canUseFont(_currentFontFamily)) return 'System';
    return _currentFontFamily;
  }

  List<String> get availableFonts => _fontFamilies;

  bool get fontsUnlocked => RewardUnlockService.instance.fontsUnlocked;

  bool canUseFont(String fontName) =>
      freeFonts.contains(fontName) || fontsUnlocked;
  bool _isLoading = true;

  // Chapter get currentChapter => _allChapters[_currentIndex];
  // 🚨 REPLACED: Chapter get currentChapter => _allChapters[_currentIndex];

  // // ✅ NEW SAFE GETTER:
  // Chapter get currentChapter {
  //   // 1. Safety Check: Is the list completely empty?
  //   if (_allChapters.isEmpty) {
  //     // Return a temporary placeholder so the UI doesn't crash!
  //     return Chapter(
  //       id: -1,
  //       title: 'ஏற்றுகிறது...', // "Loading..." in Tamil
  //       song: '',
  //       isBookmarked: false,
  //     );
  //   }

  //   // 2. Safety Check: Is the current index somehow out of bounds?
  //   if (_currentIndex < 0 || _currentIndex >= _allChapters.length) {
  //     return _allChapters.first;
  //   }

  //   // 3. If everything is safe, return the actual chapter!
  //   return _allChapters[_currentIndex];
  // }

  // ads
  int _nextChapterClickCount = 0;
  int _previousChapterClickCount = 0;
  int _homeScreenClickCount = 0;
  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialShownAt;

  void resetChapterClickCounters() {
    _nextChapterClickCount = 0;
    _previousChapterClickCount = 0;
  }

  double get fontSize => _fontSize;

  bool get isLoading => _isLoading;

  // bool get hasNext => _currentIndex < _allChapters.length - 1;
  // bool get hasPrevious => _currentIndex > 0;

  //ads
  void loadInterstitialAd() {
    if (!AdConsentManager.canRequestAds) return;

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              AppOpenAdManager.pauseAppOpenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _interstitialAd = null;
              ad.dispose();
              AppOpenAdManager.markFullScreenAdClosed();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _interstitialAd = null;
              ad.dispose();
              AppOpenAdManager.markFullScreenAdClosed();
              loadInterstitialAd();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
          debugPrint('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  // Shared helper: shows a loading dialog, waits, closes it, then runs [showAd]
  Future<void> _showAdWithLoadingDialog(
    BuildContext context,
    VoidCallback showAd,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.brown),
            SizedBox(height: 15),
            Text(
              "விளம்பரம் ஏற்றப்படுகிறது...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    if (context.mounted) {
      Navigator.pop(context);
      showAd();
    }
  }

  bool _canShowInterstitial() {
    if (_interstitialAd == null) return false;
    if (AppOpenAdManager.pauseAppOpenAd) return false;
    if (RewardUnlockService.instance.isAdFree) return false;

    final lastShown = _lastInterstitialShownAt;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < const Duration(seconds: 60)) {
      return false;
    }
    return true;
  }

  Future<void> _maybeShowInterstitial(BuildContext context) async {
    if (!_canShowInterstitial()) return;

    final ad = _interstitialAd!;
    _lastInterstitialShownAt = DateTime.now();
    await _showAdWithLoadingDialog(context, ad.show);
  }

  // Show an interstitial at the natural break of opening a chapter, no more
  // than once every three taps and once per minute.
  Future handleHomeScreenTap(
    BuildContext context,
    VoidCallback navigateAction,
  ) async {
    _homeScreenClickCount++;

    if (_homeScreenClickCount % 3 == 0) {
      await _maybeShowInterstitial(context);
    }

    navigateAction();
  }

  ReadingProvider() {
    loadChapterstitle();
    _setupAds();
    _loadPersistedSettings();
    // Refresh the overlay when a time-limited reward (e.g. eye protection)
    // expires or is granted.
    RewardUnlockService.instance.addListener(_onRewardsChanged);
  }

  void _onRewardsChanged() => notifyListeners();

  void _setupAds() {
    // Keep listening after the initial decision so withdrawing consent in the
    // Ad privacy settings immediately disposes the preloaded interstitial.
    AdConsentManager.state.addListener(_onConsentStateChanged);
    if (AdConsentManager.canRequestAds) {
      _loadAdsAfterConsent();
    }
  }

  void _onConsentStateChanged() {
    if (AdConsentManager.canRequestAds) {
      _loadAdsAfterConsent();
      return;
    }

    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  void _loadAdsAfterConsent() {
    if (!AdConsentManager.canRequestAds) return;
    if (_interstitialAd == null) loadInterstitialAd();
  }

  @override
  void dispose() {
    RewardUnlockService.instance.removeListener(_onRewardsChanged);
    AdConsentManager.state.removeListener(_onConsentStateChanged);
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> loadChapterstitle() async {
    _isLoadingm = true;
    notifyListeners();

    _chapters = await DatabaseService.getAllChapters();

    _isLoadingm = false;
    notifyListeners();
  }

  // Initialize and load everything
  Future<void> loadChapters(int initialChapterId) async {
    _isLoading = true;

    _allChapters = await DatabaseService.getAllChapters();

    // Find the index of the tapped chapter
    _currentIndex = _allChapters.indexWhere((c) => c.id == initialChapterId);
    if (_currentIndex == -1) _currentIndex = 0;

    _isLoading = false;
    notifyListeners();
  }

  // Navigation with an interstitial at the page break after every 3 clicks.
  Future<void> nextChapter(BuildContext context) async {
    if (!hasNext) return;

    _nextChapterClickCount++;
    if (_nextChapterClickCount % 3 == 0) {
      await _maybeShowInterstitial(context);
    }

    _currentIndex++;
    notifyListeners();
  }

  /// Moves to the next song without showing an interstitial ad.
  /// Used by the audio player when a song finishes so playback continues
  /// automatically into the next song (the reading screen then updates).
  void autoAdvanceChapter() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  Future<void> previousChapter(BuildContext context) async {
    if (!hasPrevious) return;

    _previousChapterClickCount++;
    if (_previousChapterClickCount % 3 == 0) {
      await _maybeShowInterstitial(context);
    }

    _currentIndex--;
    notifyListeners();
  }

  // Font Controls
  void increaseFont() {
    if (_fontSize < 36.0) {
      _fontSize += 1.0;
      notifyListeners();
    }
  }

  void decreaseFont() {
    if (_fontSize > 15.0) {
      _fontSize -= 1.0;
      notifyListeners();
    }
  }

  void cycleFont() {
    _fontIndex = (_fontIndex + 1) % _fontFamilies.length;
    notifyListeners();
  }

  // 3. Add the method to set a specific font
  void setFontFamily(String fontName) {
    if (!canUseFont(fontName)) return;
    _currentFontFamily = fontName;
    notifyListeners();
  }

  // Eye Protection + Continuous Play + Reminder Controls
  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _eyeProtectionEnabled = prefs.getBool('eye_protection_enabled') ?? false;
    _eyeWarmth = prefs.getDouble('eye_warmth') ?? 0.3;
    _eyeDimness = prefs.getDouble('eye_dimness') ?? 0.15;
    _continuousPlayEnabled = prefs.getBool('continuous_play_enabled') ?? true;
    // Daily song reminder — 6:00 PM until the user picks another time.
    _reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
    _reminderHour = prefs.getInt('reminder_hour') ?? 18;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    notifyListeners();

    // A fresh install has the reminder enabled, so ask for notification
    // permission here as well; otherwise the OS silently blocks the reminder
    // until the user happens to toggle it off and on.
    if (_reminderEnabled) {
      await NotificationService.instance.requestPermissions();
    }

    // Keep the OS schedule in sync with the saved settings on every launch
    // (also re-arms it after a reboot/update).
    await NotificationService.instance.applyDailyReminder(
      enabled: _reminderEnabled,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  Future<void> toggleContinuousPlay() async {
    _continuousPlayEnabled = !_continuousPlayEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continuous_play_enabled', _continuousPlayEnabled);
  }

  Future<void> toggleReminder(bool value) async {
    _reminderEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);

    if (_reminderEnabled) {
      await NotificationService.instance.requestPermissions();
    }
    await NotificationService.instance.applyDailyReminder(
      enabled: _reminderEnabled,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderHour = time.hour;
    _reminderMinute = time.minute;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', _reminderHour);
    await prefs.setInt('reminder_minute', _reminderMinute);

    // Re-schedule right away so the new time takes effect today.
    await NotificationService.instance.applyDailyReminder(
      enabled: _reminderEnabled,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  Future<void> setEyeProtectionEnabled(bool value) async {
    _eyeProtectionEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eye_protection_enabled', _eyeProtectionEnabled);
  }

  Future<void> setEyeWarmth(double value) async {
    _eyeWarmth = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eye_warmth', _eyeWarmth);
  }

  Future<void> setEyeDimness(double value) async {
    _eyeDimness = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eye_dimness', _eyeDimness);
  }

  // Actions
  // void toggleBookmark() async {
  //   final chapter = _allChapters[_currentIndex];

  //   // 1. Flip the boolean! (If true, becomes false. If false, becomes true).
  //   chapter.isBookmarked = !chapter.isBookmarked;

  //   // 2. Update the UI instantly so the user doesn't feel a delay
  //   notifyListeners();

  //   // 3. Save it permanently to the SQLite database
  //   // We use chapter.id! because we know it came from the database and has an ID.
  //   if (chapter.id != null) {
  //     await DatabaseService.updateBookmark(chapter.id!, chapter.isBookmarked);
  //   }
  // }

  void toggleBookmark({required bool isFromBookmarks}) async {
    final chapter = isFromBookmarks
        ? _bookmarkedChapters[_currentIndex]
        : _allChapters[_currentIndex];

    // 1. Flip the boolean
    chapter.isBookmarked = !chapter.isBookmarked;

    // 🚨 THE FIX: Keep the bookmark list perfectly in sync in memory!
    if (chapter.isBookmarked) {
      // If we just bookmarked it, add it to the saved list
      // (We check if it's already there just to be safe and prevent duplicates)
      if (!_bookmarkedChapters.any((c) => c.id == chapter.id)) {
        _bookmarkedChapters.add(chapter);
      }
    } else {
      // If we un-bookmarked it, instantly remove it from the saved list
      _bookmarkedChapters.removeWhere((c) => c.id == chapter.id);
    }

    // 2. Update the UI instantly across ALL screens
    notifyListeners();

    // 3. Save it permanently to the SQLite database
    if (chapter.id != null) {
      await DatabaseService.updateBookmark(chapter.id!, chapter.isBookmarked);
    }
  }

  void copyToClipboard() {
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.dftacademy.thiruvasagampro';
    Clipboard.setData(
      ClipboardData(
        text:
            "${currentChapter.song} மேலும் படிக்க Thiruvasagam Pro செயலியை பதிவிறக்கம் செய்யவும்: $appLink",
      ),
    );
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('பாடல் நகலெடுக்கப்பட்டது (Copied)')),
    // );
  }

  // void shareSong() {
  //   Share.share('${currentChapter.title}\n\n${currentChapter.song}');
  // }

  void shareSong() {
    // 1. Build the link using your package name
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.dftacademy.thiruvasagampro';

    // 2. Create the message (Title + Song + Divider + Promo Message + Link)
    final String textToShare =
        '''
${currentChapter.title}

${currentChapter.song}

------------------------
மேலும் படிக்க Thiruvasagam Pro செயலியை பதிவிறக்கம் செய்யவும்:
$appLink
''';

    // Returning from the share sheet is not an app open; don't trigger an
    // app open ad on the resume.
    AppOpenAdManager.skipNextResume();

    // 3. 🚨 Share it using the NEW share_plus 13.1.0 API!
    SharePlus.instance.share(
      ShareParams(title: currentChapter.title, text: textToShare),
    );
  }

  // // 2. Add this method to load the bookmarks when the screen opens:
  Future<void> loadBookmarksall() async {
    _isLoading = true;
    notifyListeners();

    _bookmarkedChapters = await DatabaseService.getBookmarkedChapters();

    _isLoading = false;
    notifyListeners();
  }

  // 2. Update the loadChapters method to accept the new flag
  Future<void> loadBookmarks(
    int initialChapterId, {
    bool fromBookmarks = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Remember where the user came from!
    _isReadingFromBookmarks = fromBookmarks;

    if (_allChapters.isEmpty) {
      _allChapters = await DatabaseService.getAllChapters();
    }

    // 🚨 Decide which list to use for swiping!
    final activeList = _isReadingFromBookmarks
        ? _bookmarkedChapters
        : _allChapters;

    _currentIndex = activeList.indexWhere((c) => c.id == initialChapterId);
    if (_currentIndex == -1) _currentIndex = 0;

    // Remember where the reader stopped, so the daily reminder can offer the
    // next unread song instead of song 1 every time.
    if (_currentIndex >= 0 && _currentIndex < activeList.length) {
      await ReadingProgressService.markAsRead(activeList[_currentIndex].id);
    }

    _isLoading = false;
    notifyListeners();
  }

  Chapter get currentChapter {
    final activeList = _isReadingFromBookmarks
        ? _bookmarkedChapters
        : _allChapters;

    if (activeList.isEmpty) {
      return Chapter(
        id: -1,
        title: 'Loading...',
        song: '',
        isBookmarked: false,
      );
    }
    if (_currentIndex < 0 || _currentIndex >= activeList.length) {
      return activeList.first;
    }
    return activeList[_currentIndex];
  }

  bool get hasNext {
    final activeList = _isReadingFromBookmarks
        ? _bookmarkedChapters
        : _allChapters;
    return _currentIndex < activeList.length - 1;
  }

  bool get hasPrevious => _currentIndex > 0;

  // 3. Add this method to remove a bookmark from the list screen:
  Future<void> removeBookmarkFromList(int chapterId) async {
    // A. Update the SQLite database
    await DatabaseService.updateBookmark(chapterId, false);

    // B. Instantly remove it from the local list so the UI animates/updates immediately
    _bookmarkedChapters.removeWhere((chapter) => chapter.id == chapterId);

    // C. (Optional but recommended) Also update your main _allChapters list
    // so if the user goes back to the reading screen, it knows it was un-bookmarked.
    final index = _allChapters.indexWhere((c) => c.id == chapterId);
    if (index != -1) {
      _allChapters[index].isBookmarked = false;
    }

    notifyListeners();
  }

  // Future<void> toggleBookmarkWithAd(
  //   BuildContext context, {
  //   required bool isFromBookmarks,
  // }) async {
  //   // 1. Instantly save the bookmark
  //   toggleBookmark(isFromBookmarks: isFromBookmarks);

  //   // 2. Check if ad is loaded
  //   if (_interstitialAd != null) {
  //     // Show loading popup
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => AlertDialog(
  //         backgroundColor: Colors.white.withValues(alpha: 0.9),
  //         content: const Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             CircularProgressIndicator(color: Colors.brown),
  //             SizedBox(height: 15),
  //             Text(
  //               "விளம்பரம் ஏற்றப்படுகிறது...",
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );

  //     // Wait 1 second
  //     await Future.delayed(const Duration(milliseconds: 1000));

  //     // Close popup and show Ad
  //     if (context.mounted) {
  //       Navigator.pop(context);
  //       _interstitialAd!.show();
  //     }
  //   }
  // }

  // // 2. The new function to handle the Bookmark click
  // Future<void> handleBookmarkWithReward(
  //     BuildContext context, int chapterId, bool isFromBookmarks) async {

  //   // If ad is not loaded yet (e.g., no internet), just save the bookmark normally
  //   if (_rewardedInterstitialAd == null) {
  //     await toggleBookmark(chapterId, isFromBookmarks);
  //     if (context.mounted) {
  //       AppSnackBars.showBookmark(context, isBookmarked: currentChapter.isBookmarked);
  //     }
  //     return;
  //   }

  //   // Show loading popup so they don't accidentally click
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Colors.white.withOpacity(0.9),
  //       content: const Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           CircularProgressIndicator(color: Colors.brown),
  //           SizedBox(height: 15),
  //           Text("விளம்பரம் ஏற்றப்படுகிறது...", style: TextStyle(fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //     ),
  //   );

  //   // Wait 1 second
  //   await Future.delayed(const Duration(milliseconds: 1000));

  //   // Close Dialog and Show Ad
  //   if (context.mounted) {
  //     Navigator.pop(context);

  //     _rewardedInterstitialAd!.show(
  //       onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
  //         // 🚨 REWARD EARNED! Trigger the actual bookmark logic here!
  //         await toggleBookmark(chapterId, isFromBookmarks);

  //         // Show the success SnackBar
  //         if (context.mounted) {
  //            AppSnackBars.showBookmark(context, isBookmarked: currentChapter.isBookmarked);
  //         }
  //       },
  //     );
  //   }
  // }
}
