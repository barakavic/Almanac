import 'package:bookshelf/data/models/chapter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

class RegexExtractor {
  static final List<RegExp> _patterns = [
    RegExp(r'^(?:chapter|ch\.|chap\.)\s+\d+', caseSensitive: false),
    RegExp(r'^(?:chapter|ch\.|chap\.)\s+[ivxldcm]+', caseSensitive: false),
    RegExp(r'^section\s+\d+', caseSensitive: false),
    RegExp(r'^act\s+[ivxldcm]+', caseSensitive: false),
    RegExp(r'^scene\s+\d+', caseSensitive: false),
  ];

  static Future<List<Chapter>> extract(PdfDocument document, String bookId, int totalPages) async {
    final tempChapters = <_TempChapter>[];
    final extractor = PdfTextExtractor(document);

    for (int i = 0; i < totalPages; i++) {
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }

      try {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.trim().isEmpty) continue;

        final lines = text.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          bool matched = false;
          for (final pattern in _patterns) {
            if (pattern.hasMatch(trimmed)) {
              tempChapters.add(_TempChapter(title: trimmed, startPage: i + 1));
              matched = true;
              break;
            }
          }
          if (matched) break;
        }
      } catch (_) {}
    }

    if (tempChapters.isEmpty) return [];

    final chapters = <Chapter>[];
    for (int i = 0; i < tempChapters.length; i++) {
      final current = tempChapters[i];
      final isLast = i == tempChapters.length - 1;
      final endPage = isLast ? totalPages : tempChapters[i + 1].startPage - 1;

      chapters.add(Chapter(
        chapterid: const Uuid().v4(),
        bookid: bookId,
        title: current.title,
        chapterstartpagenumber: current.startPage,
        chapterendpagenumber: endPage < current.startPage ? current.startPage : endPage,
        chapterorder: i + 1,
      ));
    }
    return chapters;
  }
}

class _TempChapter {
  final String title;
  final int startPage;
  _TempChapter({required this.title, required this.startPage});
}
