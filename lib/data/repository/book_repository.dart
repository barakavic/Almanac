import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:sqflite/sqlite_api.dart';

class BookRepository {
  final DbHelper _db;
  BookRepository(this._db);

  Future<void> addBook(Book book) async { 
    final db = await _db.database;
    await db.insert('books',
     book.toMap(),
     conflictAlgorithm: ConflictAlgorithm.replace,
     
     );

   }
  Future<List<Book>> getAllBooks() async{ 
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query('books');
    return rows.map((row) => Book.fromMap(row)).toList();

  }
  Future<void> updateBook(String bookid, int page) async{ 
    final db = await _db.database;
    await db.update('books', 
    {'lastPageRead': page},
    where: 'bookId = ?',
    whereArgs: [bookid]
    
    );
  }
  Future<void> archiveBook(String bookid) async { 
    final db = await _db.database;
    await db.update(
      'books',
      {'isArchived': 1},
      where: 'bookId = ?',
      whereArgs: [bookid],
    );
  } 

  Future<void> deleteBook(String bookid) async {
    final db = await _db.database;
    await db.delete('books', 
    where: 'bookid = ?', 
    whereArgs: [bookid],
    );
  }

}