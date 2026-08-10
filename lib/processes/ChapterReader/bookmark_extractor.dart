import 'package:bookshelf/data/models/chapter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

class BookmarkExtractor {
  static List<Chapter> extract(PdfDocument document, String bookId, int totalPages) {
    final bookmarks = document.bookmarks;
    if (bookmarks.count == 0) return [];

    final tempChapters = <_TempChapter>[];
    _traverse(bookmarks, document, tempChapters);

    if (tempChapters.isEmpty) return [];

    tempChapters.sort((a, b) => a.startPage.compareTo(b.startPage));

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

  static void _traverse(PdfBookmarkBase parent, PdfDocument document, List<_TempChapter> list) {
    for (int i = 0; i < parent.count; i++) {
      final bookmark = parent[i];
      final dest = bookmark.destination;
      if (dest != null && dest.page != null) {
        final startPage = document.pages.indexOf(dest.page) + 1;
        list.add(_TempChapter(title: bookmark.title, startPage: startPage));
      }
      _traverse(bookmark, document, list);
    }
  }
}

class _TempChapter {
  final String title;
  final int startPage;
  _TempChapter({required this.title, required this.startPage});
}
