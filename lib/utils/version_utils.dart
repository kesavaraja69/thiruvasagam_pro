/// Dependency-free semantic-version helpers.
///
/// Versions in this project look like `1.8.0` or `2.0.1+12`. Anything that is
/// not a digit is ignored, so a stray `v` prefix or a `-beta` suffix never
/// throws — it simply contributes a zero segment.
class VersionUtils {
  VersionUtils._();

  static List<int> _segments(String version) {
    // Build metadata (`+12`) is handled separately by the caller.
    final core = version.split('+').first.trim();
    if (core.isEmpty) return const <int>[0];
    return core
        .split('.')
        .map((part) => int.tryParse(RegExp(r'\d+').stringMatch(part) ?? '') ?? 0)
        .toList();
  }

  /// Returns -1 when [a] is older than [b], 0 when they are equal, and 1 when
  /// [a] is newer. Missing segments count as zero, so `1.9` == `1.9.0`.
  static int compare(String a, String b) {
    final left = _segments(a);
    final right = _segments(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  /// True when [candidate] is strictly newer than [current].
  static bool isNewer(String candidate, String current) =>
      compare(candidate, current) > 0;
}
