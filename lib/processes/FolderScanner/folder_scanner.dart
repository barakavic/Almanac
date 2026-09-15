import 'dart:io';
import 'package:flutter/material.dart';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/watched_folder.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/services/book_file_metadata.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class FolderScanner {
  static const _supportedExtensions = ['.pdf', '.epub'];

  static Future<int> scan(WatchedFolder folder, BookRepository bookRepo) async {
    if (folder.absolutepath.isEmpty) return 0;

    final directory = Directory(folder.absolutepath);
    if (!directory.existsSync()) {
      appLogger.w('Watched folder does not exist: ${folder.absolutepath}');
      return 0;
    }

    int added = 0;
    final isRecursive = folder.recursive == 1;

    try {
      final entities = await directory.list(recursive: isRecursive).toList();

      for (final entity in entities) {
        if (entity is! File) continue;

        final path = entity.path.toLowerCase();
        final isSupported = _supportedExtensions.any((ext) => path.endsWith(ext));
        if (!isSupported) continue;

        final existing = await bookRepo.getBookByPath(entity.path);
        if (existing != null) continue;

        final filename = entity.uri.pathSegments.last;
        final title = filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
        final metadata = await BookFileMetadata.fromPath(entity.path);

        final book = Book(
          bookid: const Uuid().v4(),
          title: title,
          author: 'Unknown',
          filepath: entity.path,
          spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
          lastpageread: 0,
          totalpages: 0,
          isarchived: false,
          addedat: DateTime.now(),
          sha256: metadata.sha256,
          filesizebytes: metadata.fileSizeBytes,
        );

        await bookRepo.addBook(book);
        added++;
      }
    } catch (e, st) {
      appLogger.e('Error scanning folder: ${folder.absolutepath}', error: e, stackTrace: st);
    }

    return added;
  }
}
