import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/services/database_service.dart';
import 'package:thiruvasagampro/services/notification_service.dart';
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/services/rewarded_ad_service.dart';
import 'package:thiruvasagampro/services/secure_audio_store.dart';
import 'package:thiruvasagampro/utils/ad_consent_manager.dart';
import 'package:thiruvasagampro/utils/app_open_ad_manager.dart';
import 'package:thiruvasagampro/utils/notification_navigator.dart';
import 'package:thiruvasagampro/view/screens/splash_screen.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';

void main() async {
  // Ensure Flutter bindings are ready before doing async work
  // 1. Initialize Flutter Bindings
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 2. 🚨 Tell the Native Splash Screen to stay on the screen!
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // 1. Unpack, decrypt, and load the database on the very first run
  await DatabaseService.seedDatabaseIfEmpty();
  // 2. Prepare local notifications (daily "read a song" reminder)
  await NotificationService.instance.initialize();
  // Tapping the reminder opens the next song that hasn't been read yet.
  NotificationService.instance.onDailyReminderTap = openNextUnreadSong;
  await NotificationService.instance.handleLaunchFromNotification();
  // Restore any active rewarded unlocks (ad-free session, fonts, offline).
  await RewardUnlockService.instance.initialize();
  // Remove decrypted playback files left behind by a previous crash.
  await SecureAudioStore.instance.cleanupTempDirectory();
  // await MobileAds.instance.initialize(); // 🚨 Initialize Ads
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ReadingProvider())],
      child: const ThiruvasagamApp(),
    ),
  );

  // 2. 🚨 Handle GDPR and Ads IN THE BACKGROUND after the app starts
  // This prevents the splash screen from freezing while waiting for the network
  // AdConsentManager.initializeConsent();
}

class ThiruvasagamApp extends StatefulWidget {
  const ThiruvasagamApp({super.key});

  @override
  State<ThiruvasagamApp> createState() => _ThiruvasagamAppState();
}

class _ThiruvasagamAppState extends State<ThiruvasagamApp> {
  late AppLifecycleReactor _appLifecycleReactor;
  late AppOpenAdManager _appOpenAdManager; // Store a reference to it

  @override
  void initState() {
    super.initState();

    // 2. Create the manager, but DO NOT call .loadAd() yet!
    _appOpenAdManager = AppOpenAdManager();
    _appLifecycleReactor = AppLifecycleReactor(
      appOpenAdManager: _appOpenAdManager,
    );

    WidgetsBinding.instance.addObserver(_appLifecycleReactor);

    // Preload the opt-in rewarded ad once consent allows it.
    RewardedAdService.instance.initialize();

    // 3. 🚨 Initialize Ads and Consent, then load the ad safely!
    AdConsentManager.initializeConsent(
      onInitializationComplete: () {
        debugPrint('AdMob Initialized! Loading App Open Ad...');
        _appOpenAdManager.loadAd();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLifecycleReactor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'திருவாசகம்',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(primarySwatch: Colors.brown),
      home: const SplashScreen(),
      // home: FutureBuilder(
      //   future: _cacheImages(context),
      //   builder: (context, snapshot) {
      //     // While the image is decoding, show a solid color loading screen
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Scaffold(
      //         // Use your backup parchment color here so the transition is seamless
      //         backgroundColor: AppColors.parchmentBase,
      //         body: const Center(
      //           child: CircularProgressIndicator(color: AppColors.vintageInk),
      //         ),
      //       );
      //     }

      //     // The exact millisecond the image is ready, show the HomeScreen!
      //     return const SplashScreen();
      //   },
      // ),
    );
  }
}
