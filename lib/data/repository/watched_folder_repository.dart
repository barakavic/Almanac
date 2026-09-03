import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/watched_folder.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqlite_api.dart';

class WatchedFolderRepository {
  final DbHelper _db;
  WatchedFolderRepository(this._db);

  Future<void> addFolder(WatchedFolder folder) async{
    try {
      final db = await _db.database;
      await db.insert(
        'watched_folders', 
        folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
        );

    } 
    catch (e) {
      appLogger.e('Failed to add watchedfolder', error: e);
      rethrow;
      
    }
  }

  Future<List<WatchedFolder>> getFolderForDevice(String deviceId) async{
    try{
    final db = await _db.database;

    final rows = await db.query(
      'watched_folders',
      where: 'deviceid = ?',
      whereArgs: [deviceId]
    );

    return rows.map((row) => WatchedFolder.fromMap(row)).toList();
    }
    catch(e,st){
      appLogger.e('Failed to get watchedfolder by device', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<WatchedFolder>> getAllFolders() async{
    try {
      final db = await _db.database;
      final List<Map<String,dynamic>> rows  = await db.query(
        'watched_folders',
        );
        return rows.map((row) => WatchedFolder.fromMap(row)).toList();
    } catch (e,st) {
      appLogger.e('Failed to fetch all wathced folders', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateLastScannedTimestamp(String folderid, String timestamp) async{
    try{
      final db = await _db.database;
    await db.update('watched_folders', 
    {'lastscannedat': timestamp},
    where: 'folderid = ?',
    whereArgs: [folderid]
    
    );
  }
  catch(e,st){
    appLogger.e('Failed to update the lastscanned timestamp', error: e, stackTrace: st);
    rethrow;
  }
  }

  Future<int> deleteFolder(String folderid) async{
    try {
      final db = await _db.database;

      final deleteStatus = await db.delete(
        'watched_folders',
        where: 'folderid = ?',
        whereArgs: [folderid]
      );
      return deleteStatus;

    } catch (e, st) {
      appLogger.e('Failed to delete watched folder', error: e, stackTrace: st);
      rethrow;
      
    }
  }

  

}