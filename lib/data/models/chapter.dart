import 'package:bookshelf/utils/app_logger.dart';

class Chapter {
  final String chapterid;
  final String bookid;
  final String title;
  final int? chapterswatchcolor;
  final int chapterstartpagenumber;
  final int chapterendpagenumber;
  final int chapterorder;

  const Chapter({
    required this.chapterid,
    required this.bookid,
    required this.title,
    this.chapterswatchcolor,
    required this.chapterstartpagenumber,
    required this.chapterendpagenumber,
    required this.chapterorder,
  });

  int get pagenumber => chapterstartpagenumber;

  Map<String, dynamic> toMap() {
    return {
      'chapterid': chapterid,
      'bookid': bookid,
      'title': title,
      'chapterswatchcolor': chapterswatchcolor,
      'chapterstartpagenumber': chapterstartpagenumber,
      'chapterendpagenumber': chapterendpagenumber,
      'chapterorder': chapterorder,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    try {
      return Chapter(
        chapterid: map['chapterid'] ?? '',
        bookid: map['bookid'] ?? '',
        title: map['title'] ?? '',
        chapterswatchcolor: map['chapterswatchcolor'],
        chapterstartpagenumber: map['chapterstartpagenumber'] ?? 0,
        chapterendpagenumber: map['chapterendpagenumber'] ?? 0,
        chapterorder: map['chapterorder'] ?? 0,
      );
    } catch (e, st) {
      appLogger.e('Failed to parse Chapter. Map $map', error: e, stackTrace: st);
      rethrow;
    }
  }
}
