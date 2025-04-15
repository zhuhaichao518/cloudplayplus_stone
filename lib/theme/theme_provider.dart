import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
//import 'package:google_fonts/google_fonts.dart';
import '../services/shared_preferences_manager.dart';

final lightTheme0 = FlexThemeData.light(
  colors: const FlexSchemeColor(
    primary: Color(0xff1145a4),
    primaryContainer: Color.fromARGB(255, 76, 141, 255),
    secondary: Color(0xffb61d1d),
    secondaryContainer: Color(0xffec9f9f),
    tertiary: Color(0xff376bca),
    tertiaryContainer: Color(0xffcfdbf2),
    appBarColor: Color(0xffcfdbf2),
    error: Color(0xffb00020),
  ),
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 7,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 10,
    blendOnColors: false,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
  //fontFamily: GoogleFonts.notoSans().fontFamily,
  //fontFamily: 'heiti',
);

final darkTheme0 = FlexThemeData.dark(
  colors: const FlexSchemeColor(
    primary: Color(0xff376bca),
    primaryContainer: Color.fromARGB(255, 76, 141, 255),
    secondary: Color(0xfff1bbbb),
    secondaryContainer: Color(0xffcb6060),
    tertiary: Color(0xff376bca),
    tertiaryContainer: Color(0xff7297d9),
    appBarColor: Color(0xffdde5f5),
    error: null,
  ),
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 13,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
    //haichao:maybe only need this for windows. it is blured for windows.
    toggleButtonsSchemeColor: SchemeColor.inversePrimary,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
  //fontFamily: GoogleFonts.notoSans().fontFamily,
  //fontFamily: 'heiti',
);

final lightTheme1 = FlexThemeData.light(
  scheme: FlexScheme.deepOrangeM3,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 7,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 10,
    blendOnColors: false,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    dialogRadius: 6.0,
    useInputDecoratorThemeInDialogs: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
  //fontFamily: GoogleFonts.notoSans().fontFamily,
  //fontFamily: 'heiti',
);

const Color orangeColor = Color(0xffff6c0a);

final darkTheme1 = FlexThemeData.dark(
  scheme: FlexScheme.deepOrangeM3,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 13,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    dialogRadius: 6.0,
    useInputDecoratorThemeInDialogs: true,
    toggleButtonsSchemeColor: SchemeColor.inversePrimary,
  ),
  colors: const FlexSchemeColor(
    primary: Color(0xFFEA580C),
    primaryContainer: Color(0xFFEA580C),
    secondary: Color(0xFF292524),
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
);

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  ThemeData _currentlightTheme = lightTheme0;
  ThemeData _currentdarkTheme = darkTheme0;

  Future<void> _loadTheme() async {
    int themeIndex = SharedPreferencesManager.getInt('themeIndex') ?? 0;
    int streamingmode = SharedPreferencesManager.getInt('streamingMode') ?? 0;
    setThemeMode(themeIndex);
    setStreamingMode(streamingmode);
    notifyListeners();
  }

  ThemeProvider() {
    _loadTheme();
  }

  void setThemeMode(int mode) {
    if (mode == 0) {
      _themeMode = ThemeMode.light;
    } else if (mode == 1) {
      _themeMode = ThemeMode.system;
    } else if (mode == 2) {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setStreamingMode(int mode) {
    if (mode == 0) {
      _currentlightTheme = lightTheme0;
      _currentdarkTheme = darkTheme0;
    } else {
      _currentlightTheme = lightTheme1;
      _currentdarkTheme = darkTheme1;
    }
    notifyListeners();
  }

  ThemeData get lightTheme => kIsWeb
      ? _currentlightTheme
      : _currentlightTheme.useSystemChineseFont(Brightness.light);

  ThemeData get darkTheme => kIsWeb
      ? _currentdarkTheme
      : _currentdarkTheme.useSystemChineseFont(Brightness.dark);
}
