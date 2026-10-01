import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/services/reading_session_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detect returns null when the file is missing', () async {
    final book = Book(
      bookid: 'book-1',
      title: 'Test Book',
      author: 'Author',
      filepath: '${Directory.systemTemp.path}/missing-book.pdf',
      spinecolor: 0,
      lastpageread: 1,
      totalpages: 100,
      isarchived: false,
      addedat: DateTime.now(),
    );

    final result = await ReadingSessionDetector().detect(book);
    expect(result, isNull);
  });
}
