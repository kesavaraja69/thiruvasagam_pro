import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thiruvasagampro/utils/app_assets.dart';
import 'package:thiruvasagampro/utils/app_colors.dart';
import 'package:thiruvasagampro/utils/responsive_theme.dart';
import 'package:thiruvasagampro/view/screens/reading_screen.dart';
import 'package:thiruvasagampro/view/widgets/antique_header.dart';
import 'package:thiruvasagampro/viewmodels/reading_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReadingProvider>(context);

    return Scaffold(
      // Optional: Add your parchment background image here
      backgroundColor: AppColors.transparent,

      body: Column(
        children: [
          AntiqueHeader(title: 'திருவாசகம்', userScale: 1.3),

          provider.isLoadingm
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.brown),
                )
              : Expanded(
                  child: ListView.separated(
                    itemCount: provider.chapters.length,
                    padding: const EdgeInsets.only(bottom: 100),
                    separatorBuilder: (context, index) => Padding(
                      // The vertical padding creates space between the text and the image
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 22,
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
                      final chapter = provider.chapters[index];
                      return ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        title: Text(
                          "${index + 1}. ${chapter.title}",
                          style: ResponsiveText.chapterTitle(
                            context,
                            userScale: 1.2,
                          ),
                        ),
                        onTap: () {
                          debugPrint("Tapped: ${chapter.title}");
                          provider.handleHomeScreenTap(context, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReadingScreen(chapterId: index + 1),
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
    );
  }
}
