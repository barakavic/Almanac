import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:sqflite/sqlite_api.dart';

class GenreRepository {
  final DbHelper _db;
  GenreRepository(this._db);



  Future<void> addGenres(Genre genre) async{
    final name = genre.name.trim();
    if (name.isEmpty) return;

    
    final db = await _db.database;

    final existing = await db.query(
      'genre',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    
    await db.insert('genre', 
    genre.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace
    );

  }
  Future<List<Genre>> getAllGenres() async{
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query('genre');
    return rows.map((row)=> Genre.fromMap(row)).toList();
    

  }

  Future<void> updateGenre(String genreid, String name) async{
    final db = await _db.database;
    await db.update('genre', 
    {'name': name},
    where: 'genreid = ?',
    whereArgs: [genreid]
    );
  }

  Future<void> deleteGenre(String genreid) async {
    final db = await _db.database;
    final rowsDeleted = await db.delete(
      'genre',
      where: 'genreid = ?',
      whereArgs: [genreid],
    );

    if (rowsDeleted == 0) {
      throw Exception('No genre found with id "$genreid".');
    }
  }

  
}