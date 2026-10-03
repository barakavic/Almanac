import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/chapter.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class ChapterRepository {
  final DbHelper _db;
  ChapterRepository(this._db);

  Future<void> addChapter(Chapter chapter) async {
    try {
      final db = await _db.database;
      await db.insert(
        'chapters',
        chapter.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      appLogger.e('Failed to add chapter', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> addChaptersIfNone(String bookid, List<Chapter> chapters) async {
    if (chapters.isEmpty) return false;

    try {
      final db = await _db.database;
      return db.transaction((transaction) async {
        final existing = await transaction.query(
          'chapters',
          columns: ['chapterid'],
          where: 'bookid = ?',
          whereArgs: [bookid],
          limit: 1,
        );
        if (existing.isNotEmpty) return false;

        for (final chapter in chapters) {
          await transaction.insert(
            'chapters',
            chapter.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return true;
      });
    } catch (e, st) {
      appLogger.e('Failed to add extracted chapters', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Chapter>> getChaptersForBook(String bookid) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'chapters',
        where: 'bookid = ?',
        whereArgs: [bookid],
        orderBy: 'chapterorder ASC',
      );
      return rows.map((row) => Chapter.fromMap(row)).toList();
    } catch (e, st) {
      appLogger.e(
        'Failed to retrieve chapters for book',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> deleteChaptersForBook(String bookid) async {
    try {
      final db = await _db.database;
      await db.delete('chapters', where: 'bookid = ?', whereArgs: [bookid]);
    } catch (e, st) {
      appLogger.e(
        'Failed to delete chapters for book',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
