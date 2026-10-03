import 'dart:io';

import 'package:bookshelf/processes/ChapterReader/toc_crawler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('TOCCrawler.parseTOCText', () {
    test(
      'parses common entries, sorts pages, deduplicates, and fills ranges',
      () {
        final chapters = TOCCrawler.parseTOCText(
          '''TABLE OF CONTENTS
Chapter 1: Introduction ........ 5
1. Deep Dive ................... 20
Conclusion                      50
A short noise line
Contents .... 2
Chapter 1: A longer Introduction ..... 5''',
          'book-1',
          55,
        );

        expect(chapters, hasLength(3));
        expect(chapters.map((chapter) => chapter.title), [
          'Chapter 1: A longer Introduction',
          '1. Deep Dive',
          'Conclusion',
        ]);
        expect(chapters.map((chapter) => chapter.chapterstartpagenumber), [
          5,
          20,
          50,
        ]);
        expect(chapters.map((chapter) => chapter.chapterendpagenumber), [
          19,
          49,
          55,
        ]);
        expect(chapters.map((chapter) => chapter.chapterorder), [1, 2, 3]);
        expect(chapters.every((chapter) => chapter.bookid == 'book-1'), isTrue);
      },
    );

    test('accepts Roman numeral page labels and rejects invalid entries', () {
      final chapters = TOCCrawler.parseTOCText(
        'Preface ........ iv\nChapter I: Opening ..... 1\n.. .... 0\n',
        'book-2',
        10,
      );

      expect(chapters, hasLength(2));
      expect(chapters.first.chapterstartpagenumber, 1);
      expect(chapters.last.chapterstartpagenumber, 4);
      expect(chapters.first.chapterendpagenumber, 3);
      expect(chapters.last.chapterendpagenumber, 10);
    });
  });

  test('finds and crawls a TOC from an already-open document', () {
    final generated = PdfDocument();
    generated.pages.add().graphics.drawString(
      'TABLE OF CONTENTS\nChapter 1: Start ........ 2\nChapter 2: Finish ....... 4',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(20, 20, 500, 100),
    );
    generated.pages.add();
    generated.pages.add();
    generated.pages.add();
    final bytes = generated.saveSync();
    generated.dispose();

    final loaded = PdfDocument(inputBytes: bytes);
    try {
      expect(TOCCrawler.findTOCPage(loaded), 0);
      final chapters = TOCCrawler.crawlFromDocument(loaded, 'book-3', 4);
      expect(chapters.map((chapter) => chapter.title), [
        'Chapter 1: Start',
        'Chapter 2: Finish',
      ]);
      expect(chapters.map((chapter) => chapter.chapterendpagenumber), [3, 4]);
    } finally {
      loaded.dispose();
    }
  });

  test('opens, crawls, and disposes a PDF from a file path', () async {
    final generated = PdfDocument();
    generated.pages.add().graphics.drawString(
      'Contents\nChapter 1: File-based TOC .... 1',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(20, 20, 500, 100),
    );
    final bytes = generated.saveSync();
    generated.dispose();

    final tempDirectory = await Directory.systemTemp.createTemp('toc-crawler-');
    final pdfFile = File('${tempDirectory.path}/toc.pdf');
    await pdfFile.writeAsBytes(bytes);

    try {
      final chapters = await TOCCrawler.crawlTOC(pdfFile.path, 'book-file');
      expect(chapters, hasLength(1));
      expect(chapters.single.title, 'Chapter 1: File-based TOC');
      expect(chapters.single.chapterendpagenumber, 1);
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });
}
