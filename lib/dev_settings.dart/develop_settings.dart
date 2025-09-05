// To develop with chrome, add the flag --disable-web-security or debug with
// export CHROME_EXECUTABLE="/var/lib/flatpak/app/com.google.Chrome/current/active/export/bin/com.google.Chrome"
// flutter run -d chrome --web-browser-flag "--disable-web-security"
// or run.py and /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --web-browser-flag --disable-web-security --user-data-dir=/Users/zhuhaichao/Dev/chrome_user_dir

class DevelopSettings {
  static bool useUnsafeServer = false;
  static bool useLocalServer = false;
  static bool useSecureStorage = false;
  static bool alwaysShowIntroPage = false;
  static bool useRTCTestServer = false;
  static bool isDebugging = false;
}
