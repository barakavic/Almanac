import 'package:bookshelf/data/models/chapter.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/processes/ChapterReader/bookmark_extractor.dart';
import 'package:bookshelf/processes/ChapterReader/regex_extractor.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ChapterExtractor {
  static Future<void> extract({
    required WidgetRef ref,
    required PdfDocument document,
    required String bookId,
    required int totalPages,
  }) async {
    try {
      final repository = ref.read(chaptersRepositoryProvider);
      final existing = await repository.getChaptersForBook(bookId);
      if (existing.isNotEmpty) return;

      List<Chapter> chapters = BookmarkExtractor.extract(document, bookId, totalPages);

      if (chapters.isEmpty) {
        chapters = await RegexExtractor.extract(document, bookId, totalPages);
      }

      if (chapters.isNotEmpty) {
        for (final chapter in chapters) {
          await repository.addChapter(chapter);
        }
        ref.invalidate(chaptersByBookProvider(bookId));
      }
    } catch (e, st) {
      appLogger.e('Failed to extract chapters', error: e, stackTrace: st);
    }
  }
}
