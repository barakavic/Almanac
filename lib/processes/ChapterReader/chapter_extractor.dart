import 'package:bookshelf/data/models/chapter.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/processes/ChapterReader/bookmark_extractor.dart';
import 'package:bookshelf/processes/ChapterReader/regex_extractor.dart';
import 'package:bookshelf/processes/ChapterReader/toc_crawler.dart';
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
      final bookRepository = ref.read(bookRepositoryProvider);
      if (existing.isNotEmpty) {
        await bookRepository.markBookIndexed(bookId, 1);
        ref.invalidate(booksProvider);
        return;
      }

      List<Chapter> chapters = BookmarkExtractor.extract(
        document,
        bookId,
        totalPages,
      );

      if (chapters.isEmpty) {
        chapters = await TOCCrawler.crawlFromDocument(
          document,
          bookId,
          totalPages,
        );
      }

      if (chapters.isEmpty) {
        chapters = await RegexExtractor.extract(document, bookId, totalPages);
      }

      if (chapters.isNotEmpty) {
        await repository.addChaptersIfNone(bookId, chapters);
        await bookRepository.markBookIndexed(bookId, 1);
        ref.invalidate(booksProvider);
        ref.invalidate(chaptersByBookProvider(bookId));
      } else {
        await bookRepository.markBookIndexed(bookId, 2);
        ref.invalidate(booksProvider);
      }
    } catch (e, st) {
      appLogger.e('Failed to extract chapters', error: e, stackTrace: st);
    }
  }
}
