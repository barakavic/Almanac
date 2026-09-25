import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ReadingSessionDetector {
  Future<int?> detect(Book book) async {
    final filepath = book.filepath;
    if (filepath == null || filepath.isEmpty) {
      return null;
    }

    final file = File(filepath);
    if (!await file.exists()) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    final storedHash = prefs.getString('hash_${book.bookid}');
    final storedSnapshotJson = prefs.getString('snapshot_${book.bookid}');
    final sessionStart = prefs.getString('session_start_${book.bookid}');
    final lastReader = prefs.getString('last_reader_${book.bookid}');

    final _ = (storedSnapshotJson, sessionStart, lastReader);

    final fileBytes = await file.readAsBytes();
    final currentHash = sha256.convert(fileBytes).toString();

    if (storedHash == null || storedHash == currentHash) {
      return null;
    }

    final currentSnapshot = _snapshotFromPdf(fileBytes);
    final previousSnapshot = _decodeSnapshot(storedSnapshotJson);

    final highestGrowthPage = _highestPageWithGrowth(currentSnapshot, previousSnapshot);
    if (highestGrowthPage != null) {
      return highestGrowthPage;
    }

    final openActionPage = _tryOpenActionFallback(fileBytes);
    if (openActionPage != null) {
      return openActionPage;
    }

    return null;
  }

  Map<int, int> _decodeSnapshot(String? rawSnapshot) {
    if (rawSnapshot == null || rawSnapshot.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawSnapshot);

      if (decoded is! Map) {
        return {};
      }

      final result = <int, int>{};

      for (final entry in decoded.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = entry.value;

        if (key != null && value is num) {
          result[key] = value.toInt();
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  Map<int, int> _snapshotFromPdf(List<int> pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    try {
      final snapshot = <int, int>{};

      for (int i = 0; i < document.pages.count; i++) {
        final count = document.pages[i].annotations.count;
        if (count > 0) {
          snapshot[i + 1] = count;
        }
      }

      return snapshot;
    } finally {
      document.dispose();
    }
  }

  int? _highestPageWithGrowth(Map<int, int> current, Map<int, int> previous) {
    int? highestPage;

    for (final entry in current.entries) {
      final pageNumber = entry.key;
      final currentCount = entry.value;
      final previousCount = previous[pageNumber];

      if (previousCount != null && currentCount > previousCount) {
        if (highestPage == null || pageNumber > highestPage) {
          highestPage = pageNumber;
        }
      }
    }

    return highestPage;
  }

  int? _tryOpenActionFallback(List<int> pdfBytes) {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      try {
        return null;
      } finally {
        document.dispose();
      }
    } catch (_) {
      return null;
    }
  }
}

Future<int?> detect(Book book) => ReadingSessionDetector().detect(book);