import 'dart:io';
import 'package:cloudplayplus/services/login_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Need to add this when using SharedPreferences or PathProvider :
  // TestWidgetsFlutterBinding.ensureInitialized(); 

  test('verify latest version', () async {
    // Use real network request in this test.
    // https://github.com/flutter/flutter/issues/35318
    HttpOverrides.global = null;
    LoginService.init();
    String latestVersion = await LoginService.getLatestVersion();
    expect(latestVersion, "1.0.9");
  });
}