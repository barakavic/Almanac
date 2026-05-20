import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:sqflite/sqlite_api.dart';

class GenreRepository {
  final DbHelper _db;
  GenreRepository(this._db);

  Future<void> addGenres(Genre genre) async{
    final db = await _db.database;
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
}