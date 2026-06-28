import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/chapters.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class ChapterRepository {
  final DbHelper _db;
  ChapterRepository (this._db);

  Future<void> addChapter(Chapter chapter) async{
    
    try{
      final db = await _db.database;
      await db.insert('chapter', 
      chapter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    catch(e, st){
      appLogger.e('Failed to add chapter', error: e, stackTrace: st);
      rethrow;

    }
  }

  Future<List<Chapter>> getAllChapters() async{
    try{
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query('chapter');
    return rows.map((row) => Chapter.fromMap(row)).toList();
    }
    catch(e, st){
      appLogger.e('Failed to retrieve books', error: e, stackTrace: st);
      rethrow;

    }
  }

  Future<void> deleteChapter(String chapterid) async{
    try{
    final db = await _db.database;
    await db.delete(
    'chapter',
    where: 'chapterid = ?',
    whereArgs: [chapterid]
    );
    
    }
    catch(e,st){
      appLogger.e('Failed to delete chapter', error: e, stackTrace: st);
      rethrow;
    }

  }

  Future<void> updateChapterSwatchColor(String chapterid, int swatchcolor) async{
    try{
    final db = await _db.database;
    await db.update(
    'chapter',
    {'chapterswtachcolor': swatchcolor},
    where: 'chapterid = ?',
    whereArgs: [chapterid]
    );
    }
    catch(e, st){
      appLogger.e('Failed to updateSwatchColor', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Chapter>> getChaptersByBook(String bookid) async{
    try{
      final db =  await _db.database;
      final rows = await db.query(
      'chapter',
      where: 'bookid = ?',
      whereArgs: [bookid],
      orderBy: 'chapterorder ASC',
      );

    return rows.map((row) => Chapter.fromMap(row)).toList();

    }
    catch(e, st){
      appLogger.e('Failed to create chapter', error: e, stackTrace: st);
      rethrow;
    }

  }



}