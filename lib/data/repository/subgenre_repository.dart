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
}