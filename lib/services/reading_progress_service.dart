import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';
import 'database_service.dart';

/// Remembers which song the reader stopped at.
///
/// The daily reminder uses this to open the *next* song that hasn't been read
/// yet instead of always jumping back to the beginning of the book.
class ReadingProgressService {
  ReadingProgressService._();

  static const String _lastReadKey = 'last_read_chapter_id';

  /// Stores the song the reader just opened.
  static Future<void> markAsRead(int? chapterId) async {
    if (chapterId == null || chapterId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadKey, chapterId);
  }

  static Future<int?> lastReadChapterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadKey);
  }

  /// The song right after the last one that was read.
  /// Falls back to the first song when nothing has been read yet, and wraps
  /// back to the start once the last song has been reached.
  static Future<int?> nextUnreadChapterId() async {
    final chapters = await DatabaseService.getAllChapters();
    return nextUnreadFrom(chapters, await lastReadChapterId());
  }

  /// Pure part of [nextUnreadChapterId], kept separate so it can be tested
  /// without a database.
  static int? nextUnreadFrom(List<Chapter> chapters, int? lastReadChapterId) {
    if (chapters.isEmpty) return null;

    final firstId = chapters.first.id;
    if (lastReadChapterId == null) return firstId;

    final index = chapters.indexWhere(
      (chapter) => chapter.id == lastReadChapterId,
    );
    if (index == -1 || index >= chapters.length - 1) return firstId;

    return chapters[index + 1].id ?? firstId;
  }
}
