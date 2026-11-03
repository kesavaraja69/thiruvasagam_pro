import 'package:flutter_test/flutter_test.dart';
import 'package:thiruvasagampro/models/chapter.dart';
import 'package:thiruvasagampro/services/reading_progress_service.dart';

List<Chapter> _chapters(List<int> ids) => ids
    .map((id) => Chapter(id: id, title: 'Song $id', song: 'lyrics $id'))
    .toList();

void main() {
  group('ReadingProgressService.nextUnreadFrom', () {
    test('returns the first song when nothing has been read yet', () {
      expect(
        ReadingProgressService.nextUnreadFrom(_chapters([1, 2, 3]), null),
        1,
      );
    });

    test('returns the song after the last read one', () {
      expect(
        ReadingProgressService.nextUnreadFrom(_chapters([1, 2, 3]), 1),
        2,
      );
      expect(
        ReadingProgressService.nextUnreadFrom(_chapters([1, 2, 3]), 2),
        3,
      );
    });

    test('wraps back to the first song after the last one', () {
      expect(
        ReadingProgressService.nextUnreadFrom(_chapters([1, 2, 3]), 3),
        1,
      );
    });

    test('falls back to the first song when the saved id is unknown', () {
      expect(
        ReadingProgressService.nextUnreadFrom(_chapters([1, 2, 3]), 99),
        1,
      );
    });

    test('returns null when there are no chapters', () {
      expect(ReadingProgressService.nextUnreadFrom([], 1), isNull);
    });
  });
}
