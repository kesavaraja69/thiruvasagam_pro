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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.readingMaxWidth(context),
                      ),
                      child: ListView.separated(
                        itemCount: provider.chapters.length,
                        padding: EdgeInsets.only(
                          bottom: Responsive.padding(context, 100),
                        ),
                        separatorBuilder: (context, index) => Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: Responsive.padding(context, 22),
                          ),
                          child: Image.asset(
                            AppAssets.templeDivider,
                            height: Responsive.dim(context, 14),
                            width: Responsive.dim(context, 120),
                            fit: BoxFit.fill,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final chapter = provider.chapters[index];
                          return ListTile(
                            titleAlignment: ListTileTitleAlignment.center,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.padding(context, 24),
                              vertical: 0,
                            ),
                            title: Text(
                              "${index + 1}. ${chapter.title}",
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
                  ),
                ),
        ],
      ),
    );
  }
}
