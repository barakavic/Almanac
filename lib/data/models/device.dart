import 'package:bookshelf/utils/app_logger.dart';

class Device {
  final String? deviceid;
  final String? devicename;
  final String? platform;
  final String macaddress;
  final String? mdnshostname;
  final int port;
  final String createdat;
  final String lastseenat;

  const Device({
    this.deviceid,
    this.devicename,
    this.platform,
    required this.macaddress,
    this.mdnshostname,
    required this.port,
    required this.createdat,
    required this.lastseenat,
    });

  Map<String, dynamic> toMap() => {
    'deviceid': deviceid,
    'devicename': devicename,
    'platform': platform,
    'macaddress': macaddress,
    'mdnshostname': mdnshostname,
    'port': port,
    'createdat': createdat,
    'lastseenat': lastseenat,
  };

  factory Device.fromMap(Map<String, dynamic> map) {
    try{
    return Device(
    deviceid: map['deviceid'],
    devicename: map['devicename'],
    platform: map['platform'],
    macaddress: map['macaddress'] ?? '',
    mdnshostname: map['mdnshostname'] ?? '',
    port: map['port'] ?? 8786,
    createdat: map['createdat'] ?? '',
    lastseenat: map['lastseenat'] ?? '',
  );}
  catch(e,st)
  {
  appLogger.e('Failed to create Device Model', error: e, stackTrace: st);
  rethrow;
  }}
}