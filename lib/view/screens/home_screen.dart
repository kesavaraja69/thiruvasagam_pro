import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/models/app_update_config.dart';
import 'package:thiruvasagampro/services/app_update_service.dart';
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/screens/reading_screen.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/app_update_dialog.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart';
import 'package:thiruvasagampro/view/widgets/native_ad_card.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Guards against showing two dialogs at once when the first frame and a
  /// lifecycle resume happen close together.
  bool _isUpdateDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Wait for the first frame so the dialog never lands on a blank screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForAppUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the Play Store — or just days later — is a good moment to
    // re-check. The service throttles, so this cannot hammer the network.
    if (state == AppLifecycleState.resumed) {
      _checkForAppUpdate();
    }
  }

  Future<void> _checkForAppUpdate() async {
    if (_isUpdateDialogOpen || !mounted) return;

    final info = await AppUpdateService.instance.checkForUpdate();
    if (info == null || !mounted) return;

    _isUpdateDialogOpen = true;
    final action = await showAppUpdateDialog(context, info: info);
    _isUpdateDialogOpen = false;

    if (!mounted) return;

    if (action == UpdateDialogAction.later) {
      await AppUpdateService.instance.snooze(info.latestVersion);
      return;
    }

    final outcome = await AppUpdateService.instance.launchUpdate(info);
    if (!mounted) return;
    _showUpdateOutcome(outcome, info);
  }

  /// Only speaks up when the user would otherwise be left wondering.
  void _showUpdateOutcome(UpdateLaunchOutcome outcome, PendingUpdate info) {
    final String? message = switch (outcome) {
      // The immediate flow takes over the screen itself; only a quiet
      // background download needs explaining.
      UpdateLaunchOutcome.playUpdateStarted =>
        info.forceUpdate
            ? null
            : 'புதுப்பிப்பு பின்னணியில் பதிவிறக்கம் ஆகிறது…',
      UpdateLaunchOutcome.failed =>
        'புதுப்பிப்பைத் தொடங்க முடியவில்லை. Play Store இல் முயற்சிக்கவும்.',
      UpdateLaunchOutcome.storeOpened || UpdateLaunchOutcome.cancelled => null,
    };

    if (message == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.vintageInk,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReadingProvider>(context);
    final isPhone = Responsive.isPhone(context);

    // Native ads only appear when a live (or test) native unit is configured.
    final showNativeSlot =
        AdHelper.nativeAdsAvailable &&
        !RewardUnlockService.instance.isAdFree &&
        provider.chapters.length > 5;
    const int nativeAdPosition = 5;
    final itemCount = provider.chapters.length + (showNativeSlot ? 1 : 0);

    return Scaffold(
      // Optional: Add your parchment background image here
      backgroundColor: AppColors.transparent,

      body: Column(
        children: [
          AntiqueHeader(title: 'திருவாசகம்', userScale: 1.3),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: Column(
                  children: [
                    // Second banner unit, placed inline between the header and
                    // the chapter list. Kept away from the tappable rows so it
                    // cannot cause accidental clicks.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.contentPadding(
                          context,
                          Responsive.padding(context, 12),
                          tabletValue: 16,
                        ),
                        Responsive.padding(context, 4),
                        Responsive.contentPadding(
                          context,
                          Responsive.padding(context, 12),
                          tabletValue: 16,
                        ),
                        isPhone ? Responsive.padding(context, 16) : 8,
                      ),
                      child: CustomBannerAd(
                        adUnitId: AdHelper.inlineBannerAdUnitId,
                      ),
                    ),

                    provider.isLoadingm
                        ? const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.brown,
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.separated(
                              itemCount: itemCount,
                              padding: EdgeInsets.only(
                                bottom: isPhone
                                    ? Responsive.padding(context, 100)
                                    : 120,
                              ),
                              separatorBuilder: (context, index) => Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: Responsive.contentPadding(
                                    context,
                                    Responsive.padding(context, 22),
                                    tabletValue: 24,
                                  ),
                                ),
                                child: Image.asset(
                                  AppAssets.templeDivider,
                                  height: Responsive.dim(context, 14),
                                  width: Responsive.dim(context, 120),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                if (showNativeSlot &&
                                    index == nativeAdPosition) {
                                  return const NativeAdCard();
                                }

                                final chapterIndex =
                                    showNativeSlot && index > nativeAdPosition
                                    ? index - 1
                                    : index;
                                final chapter = provider.chapters[chapterIndex];

                                return ListTile(
                                  titleAlignment: ListTileTitleAlignment.center,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Responsive.contentPadding(
                                      context,
                                      Responsive.padding(context, 24),
                                      tabletValue: 28,
                                    ),
                                    vertical: 0,
                                  ),
                                  title: Text(
                                    "${chapterIndex + 1}. ${chapter.title}",
                                    style: ResponsiveText.chapterTitle(
                                      context,
                                      userScale: 1.05,
                                    ),
                                  ),
                                  onTap: () {
                                    debugPrint("Tapped: ${chapter.title}");
                                    provider.handleHomeScreenTap(context, () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ReadingScreen(
                                            chapterId: chapterIndex + 1,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
