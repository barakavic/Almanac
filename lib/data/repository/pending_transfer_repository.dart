import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/pending_transfer.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:sqflite/sqlite_api.dart';

class PendingTransferRepository {
  final DbHelper _db;
  PendingTransferRepository(this._db);

  Future<void> enqueueTransfer(PendingTransfer transfer) async {
    try {
      final db = await _db.database;
      await db.insert(
        'pendingtransfers',
        transfer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      appLogger.e('Failed to enqueue transfer', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateStatus(String transferid, TransferStatus status) async {
    try {
      final db = await _db.database;
      await db.update(
        'pendingtransfers',
        {
          'status': status.toInt(),
          'lastattemptedat': DateTime.now().toIso8601String(),
        },
        where: 'transferid = ?',
        whereArgs: [transferid],
      );
    } catch (e, st) {
      appLogger.e('Failed to update transfer status', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> incrementRetry(String transferid) async {
    try {
      final db = await _db.database;
      await db.rawUpdate(
        '''UPDATE pendingtransfers
           SET retrycount = retrycount + 1,
               lastattemptedat = ?
           WHERE transferid = ?''',
        [DateTime.now().toIso8601String(), transferid],
      );
    } catch (e, st) {
      appLogger.e('Failed to increment retry count', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> setTempPath(String transferid, String temppath) async {
    try {
      final db = await _db.database;
      await db.update(
        'pendingtransfers',
        {'temppath': temppath},
        where: 'transferid = ?',
        whereArgs: [transferid],
      );
    } catch (e, st) {
      appLogger.e('Failed to set temp path', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> cancelTransfer(String transferid) async {
    await updateStatus(transferid, TransferStatus.cancelled);
  }

  Future<void> expireTransfer(String transferid) async {
    await updateStatus(transferid, TransferStatus.expired);
  }

  Future<List<PendingTransfer>> getActiveTransfers() async {
    try {
      final db = await _db.database;
      final terminal = [
        TransferStatus.complete.toInt(),
        TransferStatus.failed.toInt(),
        TransferStatus.cancelled.toInt(),
        TransferStatus.expired.toInt(),
      ];
      final rows = await db.query(
        'pendingtransfers',
        where: 'status NOT IN (${terminal.map((_) => '?').join(',')})',
        whereArgs: terminal,
        orderBy: 'priority DESC, createdat ASC',
      );
      return rows.map((r) => PendingTransfer.fromMap(r)).toList();
    } catch (e, st) {
      appLogger.e('Failed to get active transfers', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<PendingTransfer>> getTransfersWaitingForSource(String sourcedeviceid) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'pendingtransfers',
        where: 'sourcedeviceid = ? AND status IN (?, ?)',
        whereArgs: [
          sourcedeviceid,
          TransferStatus.queued.toInt(),
          TransferStatus.waitingForSource.toInt(),
        ],
        orderBy: 'priority DESC, createdat ASC',
      );
      return rows.map((r) => PendingTransfer.fromMap(r)).toList();
    } catch (e, st) {
      appLogger.e('Failed to get transfers waiting for source', error: e, stackTrace: st);
      return [];
    }
  }

  Future<PendingTransfer?> getTransferById(String transferid) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'pendingtransfers',
        where: 'transferid = ?',
        whereArgs: [transferid],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return PendingTransfer.fromMap(rows.first);
    } catch (e, st) {
      appLogger.e('Failed to get transfer by ID', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<PendingTransfer>> getTransfersForBook(String bookid) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'pendingtransfers',
        where: 'bookid = ?',
        whereArgs: [bookid],
        orderBy: 'createdat DESC',
      );
      return rows.map((r) => PendingTransfer.fromMap(r)).toList();
    } catch (e, st) {
      appLogger.e('Failed to get transfers for book', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<PendingTransfer>> getAllTransfers() async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'pendingtransfers',
        orderBy: 'createdat DESC',
      );
      return rows.map((r) => PendingTransfer.fromMap(r)).toList();
    } catch (e, st) {
      appLogger.e('Failed to get all transfers', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> pruneCompleted(DateTime before) async {
    try {
      final db = await _db.database;
      final terminal = [
        TransferStatus.complete.toInt(),
        TransferStatus.failed.toInt(),
        TransferStatus.cancelled.toInt(),
        TransferStatus.expired.toInt(),
      ];
      await db.delete(
        'pendingtransfers',
        where: 'status IN (${terminal.map((_) => '?').join(',')}) AND createdat < ?',
        whereArgs: [...terminal, before.toIso8601String()],
      );
    } catch (e, st) {
      appLogger.e('Failed to prune completed transfers', error: e, stackTrace: st);
      rethrow;
    }
  }
}
