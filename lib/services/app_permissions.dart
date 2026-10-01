import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<Map<Permission, PermissionStatus>> requestInitialPermissions() async {
    if (Platform.isLinux) return {};

    final permissions = <Permission>[];

    permissions.add(Permission.camera);

    if (await Permission.storage.isDenied ||
        await Permission.storage.isRestricted ||
        await Permission.storage.isPermanentlyDenied ||
        await Permission.storage.isLimited) {
      permissions.add(Permission.storage);
    }

    if (permissions.isEmpty) {
      return {};
    }

    return await permissions.request();
  }

  static Future<PermissionStatus> ensureCameraPermission() async {
    if (Platform.isLinux) return PermissionStatus.denied;

    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return status;
    }

    return Permission.camera.request();
  }

  static Future<PermissionStatus> ensureStoragePermission() async {
    if (Platform.isLinux) return PermissionStatus.denied;

    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) {
      return status;
    }

    return Permission.storage.request();
  }
}
