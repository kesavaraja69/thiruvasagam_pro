// lib/views/bookmark_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/view/widgets/app_snackbars.dart';
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
                    return const Center(
                      child: Text(
                        'எந்தப் பாடலும் சேமிக்கப்படவில்லை.', // "No songs saved"
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.vintageInk,
                        ),
                      ),
                    );
                  }

                  // The List of Bookmarks
                  return ListView.separated(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                    itemCount: provider.bookmarkedChapters.length,

                    // Use your beautiful temple divider between items!
                    separatorBuilder: (context, index) => Padding(
                      // The vertical padding creates space between the text and the image
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),

                      child: Image.asset(
                        AppAssets.templeDivider,

                        // 🚨 Adjust this height based on how thick your image is!
                        // 15-25 is usually the sweet spot for dividers.
                        height: 16,
                        width: 130,

                        // 'contain' ensures the whole ornament fits perfectly without getting chopped off
                        fit: BoxFit.fill,

                        // Optional Pro-Tip: If your image is black, but you want it to match your
                        // vintage ink color exactly, uncomment these two lines!
                        // color: AppColors.vintageInk,
                        // colorBlendMode: BlendMode.srcIn,
                      ),
                    ),

                    itemBuilder: (context, index) {
                      final chapter = provider.bookmarkedChapters[index];

                      return ListTile(
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
                            provider.removeBookmarkFromList(chapter.id!);

                            AppSnackBars.showBookmark(
                              context,
                              isBookmarked:
                                  provider.currentChapter.isBookmarked,
                              isFromBookmarks: true,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            // Using your filled bookmark icon to show it's currently saved
                            child: Image.asset(
                              AppAssets.iconBookmarkFilled,
                              width: 35,
                            ),
                          ),
                        ),

                        // Navigate to the reading screen when they tap the title!
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadingScreen(
                                chapterId: chapter.id!,
                                isFromBookmarks: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
