import 'package:bookshelf/utils/app_logger.dart';

enum TransferStatus {
  queued,
  waitingForSource,
  transferring,
  verifying,
  complete,
  failed,
  cancelled,
  expired;

  static TransferStatus fromInt(int value) => TransferStatus.values[value];
  int toInt() => index;
}

enum TransferType {
  direct,
  relay;

  static TransferType fromInt(int value) => TransferType.values[value];
  int toInt() => index;
}

class PendingTransfer {
  final String transferid,
  bookid,
  sourcedeviceid,
  targetdeviceid,
  filechecksum;

  final int filesizebytes,
  currenthop,
  priority,
  retrycount;

  final TransferStatus status;
  final TransferType transfertype;

  final String? temppath, relaydeviceid;
  final DateTime? relayrecievedat, relayexpiresat;
  final DateTime createdat, lastattemptedat;

  const PendingTransfer({
    required this.transferid,
    required this.bookid,
    required this.sourcedeviceid,
    required this.targetdeviceid,
    this.relaydeviceid,
    required this.filechecksum,
    required this.filesizebytes,
    required this.transfertype,
    required this.currenthop,
    required this.priority,
    required this.status,
    required this.retrycount,
    this.temppath,
    this.relayrecievedat,
    this.relayexpiresat,
    required this.lastattemptedat,
    required this.createdat,
  });

  factory PendingTransfer.fromMap(Map<String, dynamic> map) {
    try {
      return PendingTransfer(
        transferid: map['transferid'] ?? '',
        bookid: map['bookid'] ?? '',
        sourcedeviceid: map['sourcedeviceid'] ?? '',
        targetdeviceid: map['targetdeviceid'] ?? '',
        relaydeviceid: map['relaydeviceid'] as String?,
        filechecksum: map['filechecksum'] ?? '',
        filesizebytes: map['filesizebytes'] ?? 0,
        transfertype: TransferType.fromInt(map['transfertype'] ?? 0),
        currenthop: map['currenthop'] ?? 0,
        priority: map['priority'] ?? 0,
        status: TransferStatus.fromInt(map['status'] ?? 0),
        retrycount: map['retrycount'] ?? 0,
        temppath: map['temppath'] as String?,
        relayrecievedat: map['relayrecievedat'] != null ? DateTime.parse(map['relayrecievedat']) : null,
        relayexpiresat: map['relayexpiresat'] != null ? DateTime.parse(map['relayexpiresat']) : null,
        lastattemptedat: map['lastattemptedat'] != null ? DateTime.parse(map['lastattemptedat']) : DateTime.now(),
        createdat: map['createdat'] != null ? DateTime.parse(map['createdat']) : DateTime.now(),
      );
    } catch (e, st) {
      appLogger.e('Failed to parse the pending transfer', error: e, stackTrace: st);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'transferid': transferid,
        'bookid': bookid,
        'sourcedeviceid': sourcedeviceid,
        'targetdeviceid': targetdeviceid,
        'relaydeviceid': relaydeviceid,
        'filechecksum': filechecksum,
        'filesizebytes': filesizebytes,
        'transfertype': transfertype.toInt(),
        'currenthop': currenthop,
        'priority': priority,
        'status': status.toInt(),
        'retrycount': retrycount,
        'temppath': temppath,
        'relayrecievedat': relayrecievedat?.toIso8601String(),
        'relayexpiresat': relayexpiresat?.toIso8601String(),
        'lastattemptedat': lastattemptedat.toIso8601String(),
        'createdat': createdat.toIso8601String(),
      };
    } catch (e, st) {
      appLogger.e('Failed to write the pending transfer', error: e, stackTrace: st);
      rethrow;
    }
  }
}
