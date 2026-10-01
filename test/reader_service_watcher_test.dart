import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/services/reader_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderService File Watcher Tests', () {
    final now = DateTime.now();

    test('startWatching returns immediately when filepath is null or missing', () async {
      final bookMissing = Book(
        bookid: 'missing-watcher-1',
        title: 'Missing File',
        author: 'Author',
        filepath: null,
        spinecolor: 0,
        lastpageread: 0,
        totalpages: 100,
        isarchived: false,
        addedat: now,
      );

      await ReaderService.startWatching(bookMissing);
      expect(ReaderService.isWatching('missing-watcher-1'), isFalse);

      final bookNonExistent = Book(
        bookid: 'non-existent-watcher-2',
        title: 'Non-existent File',
        author: 'Author',
        filepath: '${Directory.systemTemp.path}/definitely_non_existent_${now.millisecondsSinceEpoch}.pdf',
        spinecolor: 0,
        lastpageread: 0,
        totalpages: 100,
        isarchived: false,
        addedat: now,
      );

      await ReaderService.startWatching(bookNonExistent);
      expect(ReaderService.isWatching('non-existent-watcher-2'), isFalse);
    });

    test('startWatching and stopWatching manage subscriptions correctly', () async {
      if (Platform.isAndroid) {
        return; // Skip watcher assertion on Android
      }

      final tempDir = await Directory.systemTemp.createTemp('watcher_test_');
      final tempFile = File('${tempDir.path}/test_book.pdf');
      await tempFile.writeAsString('Dummy PDF Content');

      final book = Book(
        bookid: 'watcher-book-1',
        title: 'Test Watcher Book',
        author: 'Author',
        filepath: tempFile.path,
        spinecolor: 0,
        lastpageread: 0,
        totalpages: 100,
        isarchived: false,
        addedat: now,
      );

      await ReaderService.startWatching(book);
      expect(ReaderService.isWatching('watcher-book-1'), isTrue);

      await ReaderService.stopWatching('watcher-book-1');
      expect(ReaderService.isWatching('watcher-book-1'), isFalse);

      await tempDir.delete(recursive: true);
    });

    test('stopAllWatching cancels all active subscriptions', () async {
      if (Platform.isAndroid) {
        return;
      }

      final tempDir = await Directory.systemTemp.createTemp('watcher_test_all_');
      final tempFile1 = File('${tempDir.path}/book1.pdf');
      final tempFile2 = File('${tempDir.path}/book2.pdf');
      await tempFile1.writeAsString('PDF 1');
      await tempFile2.writeAsString('PDF 2');

      final book1 = Book(
        bookid: 'all-1',
        title: 'Book 1',
        author: 'Author',
        filepath: tempFile1.path,
        spinecolor: 0,
        lastpageread: 0,
        totalpages: 100,
        isarchived: false,
        addedat: now,
      );

      final book2 = Book(
        bookid: 'all-2',
        title: 'Book 2',
        author: 'Author',
        filepath: tempFile2.path,
        spinecolor: 0,
        lastpageread: 0,
        totalpages: 100,
        isarchived: false,
        addedat: now,
      );

      await ReaderService.startWatching(book1);
      await ReaderService.startWatching(book2);

      expect(ReaderService.isWatching('all-1'), isTrue);
      expect(ReaderService.isWatching('all-2'), isTrue);

      await ReaderService.stopAllWatching();

      expect(ReaderService.isWatching('all-1'), isFalse);
      expect(ReaderService.isWatching('all-2'), isFalse);

      await tempDir.delete(recursive: true);
    });
  });
}
