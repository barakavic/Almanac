import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/repository/device_repository.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/utils/device_identity.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class SyncService {
  final DeviceRepository _deviceRepository;
  static const int _port = 8765;
  static const Duration _scanTimeout = Duration(milliseconds: 500);
  static const Duration _requestTimeout = Duration(seconds: 5);

  SyncService(this._deviceRepository);

  Future<String> _getLanSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      if (interfaces.isNotEmpty) {
        final ip = interfaces.first.addresses.first.address;
        final parts = ip.split('.');
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    } catch (e, st) {
      appLogger.e('Failed to resolve LAN subnet', error: e, stackTrace: st);
    }
    return '192.168.1';
  }

  Future<List<Map<String, dynamic>>> scanLan() async {
    final subnet = await _getLanSubnet();
    final discovered = <Map<String, dynamic>>[];

    final futures = <Future>[];
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_probeDevice(ip).then((result) {
        if (result != null) {
          result['ip'] = ip;
          discovered.add(result);
        }
      }));
    }

    await Future.wait(futures);
    appLogger.i('LAN scan complete: found ${discovered.length} device(s)');
    return discovered;
  }

  Future<Map<String, dynamic>?> _probeDevice(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:$_port/ping'))
          .timeout(_scanTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Device?> pairWithDevice(String targetInput) async {
    try {
      String hostIp = targetInput.trim();
      int targetPort = _port;

      if (hostIp.startsWith('{') && hostIp.endsWith('}')) {
        try {
          final parsed = jsonDecode(hostIp) as Map<String, dynamic>;
          if (parsed.containsKey('ip') && parsed['ip'] != null) {
            hostIp = parsed['ip'].toString();
          }
          if (parsed.containsKey('port') && parsed['port'] != null) {
            targetPort = int.tryParse(parsed['port'].toString()) ?? _port;
          }
        } catch (e) {
          appLogger.w('Could not parse QR JSON payload: $e');
        }
      }

      final fingerprint = await getDeviceFingerprint();

      final myDevice = Device(
        deviceid: const Uuid().v4(),
        devicename: Platform.localHostname,
        platform: Platform.operatingSystem,
        macaddress: fingerprint,
        port: _port,
        createdat: DateTime.now().toIso8601String(),
        lastseenat: DateTime.now().toIso8601String(),
      );

      final response = await http
          .post(
            Uri.parse('http://$hostIp:$targetPort/pair'),
            body: jsonEncode(myDevice.toMap()),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final remoteDevice =
            Device.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
        await _deviceRepository.addDevice(remoteDevice);
        appLogger.i('Paired with ${remoteDevice.devicename} at $hostIp:$targetPort');
        return remoteDevice;
      }

      appLogger.w('Pairing failed with status ${response.statusCode}');
      return null;
    } catch (e, st) {
      appLogger.e('Failed to pair with $targetInput', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> pingDevice(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:$_port/ping'))
          .timeout(_scanTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
