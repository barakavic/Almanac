import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqlite_api.dart';

class DeviceRepository {
  final DbHelper _db;
  DeviceRepository(this._db);

  Future<void> addDevice(Device device) async {
    try {
      final db = await _db.database;
      await db.insert(
        'devices',
        device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      appLogger.e('Failed to add device', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Device?> getDeviceByMac(String mac) async {
    try {
      final db = await _db.database;
      final List<Map<String, dynamic>> rows = await db.query(
        'devices',
        where: 'macaddress = ?',
        whereArgs: [mac],
      );
      if (rows.isEmpty) return null;
      return Device.fromMap(rows.first);
    } catch (e, st) { 
      appLogger.e('Failed to get device by MAC address', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Device>> getAllDevices() async {
    try {
      final db = await _db.database;
      final List<Map<String, dynamic>> rows = await db.query('devices');
      return rows.map((e) => Device.fromMap(e)).toList();
    } catch (e, st) {
      appLogger.e('Failed to get all devices', error: e, stackTrace: st);
      return [];
    }
  }

  Future<int> deleteDevices(String deviceid) async{
    try {
      final db = await _db.database;
      final deleteStatus = await db.delete(
        'devices',
        where: 'deviceid = ?',
        whereArgs: [deviceid]
      );
      return deleteStatus;
    } catch (e,st) {
      appLogger.e('Failed to delete device',error: e,stackTrace: st);
      rethrow;
      
    }
  }
}
