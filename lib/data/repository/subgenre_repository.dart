import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/subgenre.dart';

class SubgenreRepository {
  final DbHelper _db;
  SubgenreRepository(this._db);

  Future<List<Subgenre>> getSubgenreByGenre(String genreid) async{
    final db = await _db.database;

    final rows = await db.query(
      'subgenre',
      where: 'genreid = ?',
      whereArgs: [genreid],
    );

    return rows.map((row)=> Subgenre.fromMap(row)).toList();
  }

  Future<void> addSubgenre(Subgenre subgenre) async {
    final name = subgenre.subgenrename.trim();
    if (name.isEmpty) return;

    final db = await _db.database;

    final existing = await db.query(
      'subgenre',
      where: 'LOWER(subgenrename) = ? AND genreid = ?',
      whereArgs: [name.toLowerCase(), subgenre.genreid],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('subgenre',
      subgenre.toMap(),
    );
  }

  Future<void> deleteSubgenre(String subgenreid) async {
    final db = await _db.database;
    await db.delete(
      'subgenre',
      where: 'subgenreid = ?',
      whereArgs: [subgenreid],
    );
  }
}