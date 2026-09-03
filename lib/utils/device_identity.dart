import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getDeviceFingerprint() async{
  final preference = await SharedPreferences.getInstance();
  String? fingerprint = preference.getString('device_fingerprint');
  if (fingerprint == null){
    fingerprint = const Uuid().v4();
    await preference.setString('device_fingerprint', fingerprint);

  }
  return fingerprint;
}