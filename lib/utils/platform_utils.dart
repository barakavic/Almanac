import 'dart:io';

enum AppPlatform { android, linux, windows, macos, ios, unknown }

class PlatformUtils {
  static AppPlatform get current {
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isLinux) return AppPlatform.linux;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isIOS) return AppPlatform.ios;
    return AppPlatform.unknown;
  }

  static bool get isDesktop =>
      current == AppPlatform.linux ||
      current == AppPlatform.windows ||
      current == AppPlatform.macos;

  static bool get usesOverflowDeviceMenu => isDesktop;
  static bool get usesLongPressDeviceActions => current == AppPlatform.android;
}
