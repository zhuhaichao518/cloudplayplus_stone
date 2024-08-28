import 'dart:io';

class DeviceInfo {
  static String get label {
    return 'CloudPlayPlus ${Platform.operatingSystem} ${Platform.localHostname}';
  }

  static String get userAgent {
    return 'CloudPlayPlus ${Platform.operatingSystem} -v 0.0.1';
  }
}
