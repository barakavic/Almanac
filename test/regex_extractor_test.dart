import 'package:bookshelf/processes/ChapterReader/regex_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test(
    'collapses repeated running chapter headers into one chapter range',
    () async {
      final generated = PdfDocument();
      for (var index = 0; index < 6; index++) {
        final page = generated.pages.add();
        final heading = index < 5
            ? (index.isEven ? 'Chapter 8' : 'CHAPTER   8')
            : 'Chapter 9: Conclusion';
        page.graphics.drawString(
          heading,
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: const Rect.fromLTWH(20, 20, 500, 40),
        );
      }

      final bytes = generated.saveSync();
      generated.dispose();
      final document = PdfDocument(inputBytes: bytes);

      try {
        final chapters = await RegexExtractor.extract(
          document,
          'book-headers',
          document.pages.count,
        );

        expect(chapters, hasLength(2));
        expect(chapters.map((chapter) => chapter.title), [
          'Chapter 8',
          'Chapter 9: Conclusion',
        ]);
        expect(chapters.map((chapter) => chapter.chapterstartpagenumber), [
          1,
          6,
        ]);
        expect(chapters.map((chapter) => chapter.chapterendpagenumber), [5, 6]);
        expect(chapters.map((chapter) => chapter.chapterorder), [1, 2]);
      } finally {
        document.dispose();
      }
    },
  );
}
