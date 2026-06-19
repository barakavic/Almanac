import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqlite_api.dart';

class BookRepository {
  final DbHelper _db;
  BookRepository(this._db);

  Future<void> addBook(Book book) async { 
    try{
    final db = await _db.database;
    await db.insert('books',
     book.toMap(),
     conflictAlgorithm: ConflictAlgorithm.replace,
    );
    }
    catch(e,st){
      appLogger.e('Failed to add book', error: e, stackTrace: st);
      rethrow;
    }
     

   }
  Future<List<Book>> getAllBooks() async{ 
    try{
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query('books');
    return rows.map((row) => Book.fromMap(row)).toList();
    }
    catch(e, st){
      appLogger.e('Failed to retrieve books', error: e, stackTrace: st);
      rethrow;
    }
  }
  Future<void> updateBook(String bookid, int page) async{ 
    try{
    final db = await _db.database;
    await db.update('books', 
    {'lastPageRead': page},
    where: 'bookId = ?',
    whereArgs: [bookid]
    
    );
    }
    catch(e,st){
      appLogger.e('Failed to update book', error: e, stackTrace: st);
      rethrow;
    }
  }
  Future<void> archiveBook(String bookid) async { 
    try{final db = await _db.database;
    await db.update(
      'books',
      {'isarchived': 1},
      where: 'bookid = ?',
      whereArgs: [bookid],
    );}
    catch(e,st){
      appLogger.e('Failed to archive book', error: e, stackTrace: st);
      rethrow;
    }
  } 

  Future<void> updateBookTotalPages(String bookid, int totalpages) async {
    final db = await _db.database;
    await db.update(
      'books',
      {'totalpages': totalpages},
      where: 'bookid = ?',
      whereArgs: [bookid]
    );
  }

  Future<void> deleteBook(String bookid) async {
    try{
    final db = await _db.database;
    await db.delete('books', 
    where: 'bookid = ?', 
    whereArgs: [bookid],
    );
    }
    catch(e,st){
      appLogger.e('Failed to delete book', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Book>> getBooksByGenre(String genreid) async{
  final db = await _db.database;

  final rows =  await db.query(
    'books',
    where: 'genreid = ? AND isarchived = ?',
    whereArgs: [genreid, 0],
  );
  return rows.map((row) => Book.fromMap(row)).toList();
}

Future<Book?> getBookByPath(String filePath) async{
  final db = await _db.database;

  final rows = await db.query(
    'books',
    where: 'filepath = ?',
    whereArgs: [filePath],
    limit: 1
  );

  if (rows.isEmpty) return null;

  return Book.fromMap(rows.first);
}

Future<void> reassignBook(String bookid, String? genreid, String? subgenreid) async{
  try{
    final db = await _db.database;
    await db.update(
      'books',
      {'genreid': genreid,
       'subgenreid': subgenreid},
      where: 'bookid = ?',
      whereArgs: [bookid]
      
      );

  }
  catch(e, st){
    appLogger.e('Failed to reassign book', error: e, stackTrace: st);
    rethrow;

  }
}

/* Future<void> getGenreColorByBook(String bookid, String? genreid) async{
  try{
    final db = await _db.database;
    

  }
  catch(e, st){
    appLogger.e('Failed to get color by book', error: e, stackTrace: st);
    rethrow;
  }
}
 */
}

