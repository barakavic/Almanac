import 'dart:convert';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:http/http.dart' as http;

class HealthCheckService {
  static const Duration _timeout = Duration(seconds: 3);

  static Future<bool> checkDeviceHealth(Device device, String pairingToken) async {
    if (device.ipaddress.isEmpty || device.ipaddress == '0.0.0.0') {
      return false;
    }

    try {
      final url = Uri.parse('http://${device.ipaddress}:${device.port}/health');
      final response = await http.get(
        url,
        headers: {
          'x-almanac-token': pairingToken,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          return true;
        }
      }
    } catch (e) {
      appLogger.w('Health check failed for ${device.devicename} at ${device.ipaddress}: $e');
    }

    return false;
  }
}
