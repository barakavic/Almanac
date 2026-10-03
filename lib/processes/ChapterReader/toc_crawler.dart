import 'dart:io';

import 'package:bookshelf/data/models/chapter.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

/// Finds and parses a table of contents near the start of a PDF.
class TOCCrawler {
  static const int maxPagesToScan = 100;
  static const int maxTOCPagesToRead = 20;

  static final RegExp _tocHeading = RegExp(
    r'^\s*(?:table\s+of\s+contents|brief\s+contents|contents|toc)\b',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _entryLine = RegExp(
    r'^(.*?)\s*(?:[.·•…]{2,}|[-–—]{2,}|[ \t]{2,})\s*(\d+|[ivxlcdm]+)\s*$',
    caseSensitive: false,
  );
  static final RegExp _looseEntryLine = RegExp(
    r'^(.{4,}?)\s+(\d+|[ivxlcdm]+)\s*$',
    caseSensitive: false,
  );

  /// Opens a PDF from disk, crawls its TOC, and always disposes the document.
  static Future<List<Chapter>> crawlTOC(String filepath, String bookid) async {
    final bytes = await File(filepath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      return await crawlFromDocument(document, bookid, document.pages.count);
    } finally {
      document.dispose();
    }
  }

  /// Reuses an already-open PDF document to avoid an extra read and parse.
  static Future<List<Chapter>> crawlFromDocument(
    PdfDocument document,
    String bookid,
    int totalPages,
  ) async {
    final tocPage = await findTOCPage(document, totalPages);
    if (tocPage == null) return [];

    final pageTexts = <String>[];
    final extractor = PdfTextExtractor(document);
    var emptyPagesAfterEntries = 0;
    var foundEntry = false;
    final lastPage = (tocPage + maxTOCPagesToRead)
        .clamp(0, totalPages)
        .clamp(0, maxPagesToScan);

    for (var pageIndex = tocPage; pageIndex < lastPage; pageIndex++) {
      if (pageIndex > tocPage && (pageIndex - tocPage) % 5 == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      String pageText;
      try {
        pageText = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
          layoutText: true,
        );
      } catch (_) {
        if (foundEntry && ++emptyPagesAfterEntries >= 2) break;
        continue;
      }

      final pageEntries = _parseEntries(pageText, totalPages);
      if (pageEntries.isNotEmpty) {
        foundEntry = true;
        emptyPagesAfterEntries = 0;
        pageTexts.add(pageText);
      } else if (foundEntry) {
        emptyPagesAfterEntries++;
        if (emptyPagesAfterEntries >= 2) break;
      } else {
        // The heading page may have only a heading or a short introduction.
        pageTexts.add(pageText);
      }
    }

    return parseTOCText(pageTexts.join('\n'), bookid, totalPages);
  }

  /// Returns the zero-based index of the first likely TOC page.
  static Future<int?> findTOCPage(
    PdfDocument document, [
    int? totalPages,
  ]) async {
    final pageCount = document.pages.count;
    final scanLimit = (totalPages ?? pageCount).clamp(0, pageCount);
    final extractor = PdfTextExtractor(document);

    for (
      var pageIndex = 0;
      pageIndex < scanLimit && pageIndex < maxPagesToScan;
      pageIndex++
    ) {
      if (pageIndex > 0 && pageIndex % 5 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      try {
        final text = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );
        if (_tocHeading.hasMatch(text)) return pageIndex;
      } catch (_) {
        // A malformed or image-only page should not prevent scanning later pages.
      }
    }
    return null;
  }

  /// Parses TOC entries into ordered chapter records.
  @visibleForTesting
  static List<Chapter> parseTOCText(
    String text,
    String bookid,
    int totalPages,
  ) {
    final chaptersByPage = <int, String>{};
    for (final entry in _parseEntries(text, totalPages)) {
      final existingTitle = chaptersByPage[entry.page];
      if (existingTitle == null || entry.title.length > existingTitle.length) {
        chaptersByPage[entry.page] = entry.title;
      }
    }

    final sortedEntries = chaptersByPage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final chapters = <Chapter>[];

    for (var index = 0; index < sortedEntries.length; index++) {
      final entry = sortedEntries[index];
      chapters.add(
        Chapter(
          chapterid: const Uuid().v4(),
          bookid: bookid,
          title: entry.value,
          chapterstartpagenumber: entry.key,
          chapterendpagenumber: totalPages,
          chapterorder: index + 1,
        ),
      );
    }

    return fillEndPages(chapters, totalPages);
  }

  static List<({String title, int page})> _parseEntries(
    String text,
    int totalPages,
  ) {
    final entries = <({String title, int page})>[];
    for (final rawLine
        in text
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n')
            .replaceAll('\u00a0', ' ')
            .split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || _tocHeading.hasMatch(line)) continue;

      final match =
          _entryLine.firstMatch(line) ?? _looseEntryLine.firstMatch(line);
      if (match == null) continue;

      final title = _cleanTitle(match.group(1) ?? '');
      final page = _parsePageNumber(match.group(2) ?? '');
      if (title.length <= 3 || page == null || page <= 0 || page > totalPages) {
        continue;
      }
      entries.add((title: title, page: page));
    }
    return entries;
  }

  /// Calculates each chapter's inclusive end page from the next chapter start.
  static List<Chapter> fillEndPages(List<Chapter> chapters, int totalPages) {
    return [
      for (var index = 0; index < chapters.length; index++)
        chapters[index].copyWith(
          chapterendpagenumber: index == chapters.length - 1
              ? totalPages
              : chapters[index + 1].chapterstartpagenumber - 1,
          chapterorder: index + 1,
        ),
    ];
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'[.\s…–—-]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int? _parsePageNumber(String value) {
    final numericPage = int.tryParse(value);
    if (numericPage != null) return numericPage;

    final roman = value.toLowerCase();
    const values = <String, int>{
      'i': 1,
      'v': 5,
      'x': 10,
      'l': 50,
      'c': 100,
      'd': 500,
      'm': 1000,
    };
    var result = 0;
    var previous = 0;
    for (final character in roman.split('').reversed) {
      final current = values[character];
      if (current == null) return null;
      result += current < previous ? -current : current;
      previous = current;
    }
    return result == 0 ? null : result;
  }
}
