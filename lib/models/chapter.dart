class Chapter {
  final int? id;
  final String title;
  final String song;
  bool isBookmarked;

  Chapter({
    this.id,
    required this.title,
    required this.song,
    this.isBookmarked = false,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'],
      title: map['title'],
      song: map['song'],
      isBookmarked: map['isBookmarked'] == 1,
    );
  }
}
