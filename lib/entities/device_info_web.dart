// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DeviceInfo {
  static String get label {
    return 'CloudPlayPlus Web';
  }

  static String get userAgent {
    return 'CloudPlayPlus ${html.window.navigator.userAgent}';
  }
}
