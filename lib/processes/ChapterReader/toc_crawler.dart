import 'dart:io';

import 'package:bookshelf/data/models/chapter.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

/// Finds and parses a table of contents near the start of a PDF.
class TOCCrawler {
  static const int maxPagesToScan = 15;

  static final RegExp _tocHeading = RegExp(
    r'^\s*(?:table\s+of\s+contents|contents|toc)\b',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _entryLine = RegExp(
    r'^(.*?)\s*(?:\.{2,}|…+|[-–—]{2,}|\s{2,})\s*(\d+|[ivxlcdm]+)\s*$',
    caseSensitive: false,
  );

  /// Opens a PDF from disk, crawls its TOC, and always disposes the document.
  static Future<List<Chapter>> crawlTOC(String filepath, String bookid) async {
    final bytes = await File(filepath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      return crawlFromDocument(document, bookid, document.pages.count);
    } finally {
      document.dispose();
    }
  }

  /// Reuses an already-open PDF document to avoid an extra read and parse.
  static List<Chapter> crawlFromDocument(
    PdfDocument document,
    String bookid,
    int totalPages,
  ) {
    final tocPage = findTOCPage(document, totalPages);
    if (tocPage == null) return [];

    final text = PdfTextExtractor(
      document,
    ).extractText(startPageIndex: tocPage, endPageIndex: tocPage);
    return parseTOCText(text, bookid, totalPages);
  }

  /// Returns the zero-based index of the first likely TOC page.
  static int? findTOCPage(PdfDocument document, [int? totalPages]) {
    final pageCount = document.pages.count;
    final scanLimit = (totalPages ?? pageCount).clamp(0, pageCount);
    final extractor = PdfTextExtractor(document);

    for (
      var pageIndex = 0;
      pageIndex < scanLimit && pageIndex < maxPagesToScan;
      pageIndex++
    ) {
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
    final normalizedText = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00a0', ' ');

    for (final rawLine in normalizedText.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || _tocHeading.hasMatch(line)) continue;

      final match = _entryLine.firstMatch(line);
      if (match == null) continue;

      final title = _cleanTitle(match.group(1) ?? '');
      final startPage = _parsePageNumber(match.group(2) ?? '');
      if (title.length <= 3 || startPage == null || startPage <= 0) continue;

      final existingTitle = chaptersByPage[startPage];
      if (existingTitle == null || title.length > existingTitle.length) {
        chaptersByPage[startPage] = title;
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
