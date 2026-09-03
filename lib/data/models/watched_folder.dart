import 'package:bookshelf/utils/app_logger.dart';

class WatchedFolder {
  final String folderid;
  final String deviceid;
  final String displayname;
  final String absolutepath;
  final String? relativepath;
  final String volumeserial;
  final int isremovable;
  final int isavailable;
  final int? autoimport;
  final int? recursive;
  final int? scanstatus;
  final DateTime lastscannedat;
  final DateTime lastseenat;
  final DateTime addedat;

  const WatchedFolder({
    required this.folderid,
    required this.deviceid,
    required this.displayname,
    required this.absolutepath,
    this.relativepath,
    required this.volumeserial,
    required this.isremovable,
    required this.isavailable,
    this.autoimport,
    this.recursive,
    this.scanstatus,
    required this.lastscannedat,
    required this.lastseenat,
    required this.addedat
  });

Map<String, dynamic> toMap(){
  return {
    'folderid': folderid,
    'deviceid': deviceid,
    'displayname': displayname,
    'absolutepath': absolutepath,
    'relativepath': relativepath,
    'volumeserial': volumeserial,
    'isremovable': isremovable,
    'isavailable': isavailable,
    'autoimport': autoimport,
    'recursive': recursive,
    'scanstatus': scanstatus,
    'lastscannedat': lastscannedat.toIso8601String(),
    'lastseenat': lastseenat.toIso8601String(),
    'addedat': addedat.toIso8601String(),
  };
}

factory WatchedFolder.fromMap(Map<String, dynamic> map){
  try {
    return WatchedFolder(
    folderid: map['folderid'] ?? '', 
    deviceid: map['deviceid'] ?? '', 
    displayname: map['displayname'] ?? '', 
    absolutepath: map['absolutepath'] ?? '',
    relativepath: map['relativepath'] ?? '',
    volumeserial: map['volumeserial']?? '', 
    isremovable: map['isremovable'] ?? 0, 
    isavailable: map['isavailable'] ?? 0, 
    autoimport: map['autoimport'] ?? 0,
    recursive: map['recursive'] ?? 0,
    scanstatus: map['scanstatus'] ?? 0,
    lastscannedat: DateTime.parse(map['lastscannedat'] ?? DateTime.now().toIso8601String()) , 
    lastseenat: DateTime.parse(map['lastseenat'] ?? DateTime.now().toIso8601String()) , 
    addedat: DateTime.parse(map['addedat'] ?? DateTime.now().toIso8601String()), 
    );
  } catch (e,st) {
    appLogger.e('Failed to parse the WatchFolder Object', error: e, stackTrace: st);
    rethrow;
    
  }
}

}