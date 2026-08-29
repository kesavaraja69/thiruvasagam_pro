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
                    return Center(
                      child: Text(
                        'எந்தப் பாடலும் சேமிக்கப்படவில்லை.',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 18),
                          color: AppColors.vintageInk,
                        ),
                      ),
                    );
                  }

                  // The List of Bookmarks
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.readingMaxWidth(context),
                      ),
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        left: Responsive.padding(context, 12),
                        right: Responsive.padding(context, 12),
                        bottom: Responsive.padding(context, 100),
                      ),
                    itemCount: provider.bookmarkedChapters.length,

                    separatorBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: Responsive.padding(context, 12),
                      ),

                      child: Image.asset(
                        AppAssets.templeDivider,
                        height: Responsive.dim(context, 14),
                        width: Responsive.dim(context, 120),
                        fit: BoxFit.fill,
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
                            padding: EdgeInsets.all(
                              Responsive.padding(context, 2),
                            ),
                            child: Image.asset(
                              AppAssets.iconBookmarkFilled,
                              width: Responsive.dim(context, 30),
                            ),
                          ),
                        ),

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
                    },                    ),  // ListView.separated
                    ),  // ConstrainedBox
                    );  // Center return statement
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
