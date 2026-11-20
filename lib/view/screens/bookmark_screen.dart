// lib/views/bookmark_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/services/reward_unlock_service.dart';
import 'package:thiruvasagampro/utils/ad_helper.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/app_snackbars.dart';
import 'package:thiruvasagampro/view/widgets/custom_banner_ad.dart';
import 'package:thiruvasagampro/view/widgets/native_ad_card.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';
import 'reading_screen.dart'; // Import this to navigate to the song

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the bookmarks as soon as the screen opens!
    Future.microtask(() {
      if (mounted) {
        Provider.of<ReadingProvider>(context, listen: false).loadBookmarksall();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body: Column(
          children: [
            AntiqueHeader(
              title: 'விருப்பமானவை (Bookmarks)',
              // "Favorites / Bookmarks" in Tamil
            ),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    children: [
                      // Second banner unit, kept above the list and away from
                      // the bookmark rows so it cannot cause accidental taps.
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

                      Expanded(
                        child: Consumer<ReadingProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.vintageInk,
                                ),
                              );
                            }

                            if (provider.bookmarkedChapters.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.contentPadding(
                                      context,
                                      24,
                                      tabletValue: 48,
                                    ),
                                  ),
                                  child: Text(
                                    'எந்தப் பாடலும் சேமிக்கப்படவில்லை.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        18,
                                      ),
                                      color: AppColors.vintageInk,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final showNativeSlot =
                                AdHelper.nativeAdsAvailable &&
                                !RewardUnlockService.instance.isAdFree &&
                                provider.bookmarkedChapters.length > 3;
                            const int nativeAdPosition = 2;
                            final itemCount =
                                provider.bookmarkedChapters.length +
                                (showNativeSlot ? 1 : 0);

                            // The List of Bookmarks
                            return ListView.separated(
                              padding: EdgeInsets.only(
                                left: Responsive.contentPadding(
                                  context,
                                  Responsive.padding(context, 12),
                                  tabletValue: 16,
                                ),
                                right: Responsive.contentPadding(
                                  context,
                                  Responsive.padding(context, 12),
                                  tabletValue: 16,
                                ),
                                bottom: isPhone ? 100 : 120,
                              ),
                              itemCount: itemCount,

                              separatorBuilder: (context, index) => Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: Responsive.contentPadding(
                                    context,
                                    Responsive.padding(context, 12),
                                    tabletValue: 20,
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

                                final bookmarkIndex =
                                    showNativeSlot && index > nativeAdPosition
                                    ? index - 1
                                    : index;
                                final chapter =
                                    provider.bookmarkedChapters[bookmarkIndex];

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Responsive.contentPadding(
                                      context,
                                      Responsive.padding(context, 8),
                                      tabletValue: 20,
                                    ),
                                  ),
                                  title: Text(
                                    chapter.title,
                                    style: ResponsiveText.chapterTitle(
                                      context,
                                      userScale: 1.0,
                                    ),
                                  ),

                                  // The Remove Bookmark Button
                                  trailing: GestureDetector(
                                    onTap: () {
                                      provider.removeBookmarkFromList(
                                        chapter.id!,
                                      );

                                      AppSnackBars.showBookmark(
                                        context,
                                        isBookmarked: provider
                                            .currentChapter
                                            .isBookmarked,
                                        isFromBookmarks: true,
                                      );
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        Responsive.padding(context, 8),
                                      ),
                                      child: Image.asset(
                                        AppAssets.iconBookmarkFilled,
                                        width: Responsive.isPhone(context)
                                            ? Responsive.dim(context, 30)
                                            : 32,
                                      ),
                                    ),
                                  ),

                                  onTap: () {
                                    provider.handleBookmarkOpen(context, () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReadingScreen(
                                            chapterId: chapter.id!,
                                            isFromBookmarks: true,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                );
                              },
                            ); // ListView.separated
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
      ),
    );
  }
}
