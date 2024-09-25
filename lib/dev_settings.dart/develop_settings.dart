// To develop with chrome, add the flag --disable-web-security or debug with
// export CHROME_EXECUTABLE="/var/lib/flatpak/app/com.google.Chrome/current/active/export/bin/com.google.Chrome"
// flutter run -d chrome --web-browser-flag "--disable-web-security"
class DevelopSettings {
  static bool useLocalServer = true;
  static bool useSecureStorage = false;
  static bool alwaysShowIntroPage = false;
  static bool useRTCTestServer = true;
  static bool isDebugging = true;
}
