import 'package:flutter/cupertino.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/utils/platform_utils.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/utils/settings_theme.dart';

SettingsThemeData getTheme({
  required BuildContext context,
  required DevicePlatform platform,
  required Brightness brightness,
}) {
  switch (platform) {
    case DevicePlatform.android:
    case DevicePlatform.fuchsia:
    case DevicePlatform.linux:
      return _androidTheme(context: context, brightness: brightness);
    case DevicePlatform.iOS:
    case DevicePlatform.macOS:
    case DevicePlatform.windows:
      return _iosTheme(context: context, brightness: brightness);
    case DevicePlatform.web:
      return _webTheme(context: context, brightness: brightness);
    case DevicePlatform.device:
      throw Exception(
        "You can't use the DevicePlatform.device in this context. "
        'Incorrect platform: ThemeProvider.getTheme',
      );
  }
}

SettingsThemeData _androidTheme({
  required BuildContext context,
  required Brightness brightness,
}) {
  const lightLeadingIconsColor = Color.fromARGB(255, 70, 70, 70);
  const darkLeadingIconsColor = Color.fromARGB(255, 197, 197, 197);

  const lightSettingsListBackground = Color.fromRGBO(240, 240, 240, 1);
  const darkSettingsListBackground = Color.fromRGBO(27, 27, 27, 1);

  const lightSettingsTitleColor = Color.fromRGBO(11, 87, 208, 1);
  const darkSettingsTitleColor = Color.fromRGBO(211, 227, 253, 1);

  const lightTileHighlightColor = Color.fromARGB(255, 220, 220, 220);
  const darkTileHighlightColor = Color.fromARGB(255, 46, 46, 46);

  const lightSettingsTileTextColor = Color.fromARGB(255, 27, 27, 27);
  const darkSettingsTileTextColor = Color.fromARGB(255, 240, 240, 240);

  const lightInactiveTitleColor = Color.fromARGB(255, 146, 144, 148);
  const darkInactiveTitleColor = Color.fromARGB(255, 118, 117, 122);

  const lightInactiveSubtitleColor = Color.fromARGB(255, 197, 196, 201);
  const darkInactiveSubtitleColor = Color.fromARGB(255, 71, 70, 74);

  const lightTileDescriptionTextColor = Color.fromARGB(255, 70, 70, 70);
  const darkTileDescriptionTextColor = Color.fromARGB(255, 198, 198, 198);

  final isLight = brightness == Brightness.light;

  final listBackground =
      isLight ? lightSettingsListBackground : darkSettingsListBackground;

  final titleTextColor =
      isLight ? lightSettingsTitleColor : darkSettingsTitleColor;

  final settingsTileTextColor =
      isLight ? lightSettingsTileTextColor : darkSettingsTileTextColor;

  final tileHighlightColor =
      isLight ? lightTileHighlightColor : darkTileHighlightColor;

  final tileDescriptionTextColor =
      isLight ? lightTileDescriptionTextColor : darkTileDescriptionTextColor;

  final leadingIconsColor =
      isLight ? lightLeadingIconsColor : darkLeadingIconsColor;

  final inactiveTitleColor =
      isLight ? lightInactiveTitleColor : darkInactiveTitleColor;

  final inactiveSubtitleColor =
      isLight ? lightInactiveSubtitleColor : darkInactiveSubtitleColor;

  return SettingsThemeData(
    tileHighlightColor: tileHighlightColor,
    settingsListBackground: listBackground,
    titleTextColor: titleTextColor,
    settingsTileTextColor: settingsTileTextColor,
    tileDescriptionTextColor: tileDescriptionTextColor,
    leadingIconsColor: leadingIconsColor,
    inactiveTitleColor: inactiveTitleColor,
    inactiveSubtitleColor: inactiveSubtitleColor,
  );
}

SettingsThemeData _iosTheme({
  required BuildContext context,
  required Brightness brightness,
}) {
  const lightSettingsListBackground = Color.fromRGBO(242, 242, 247, 1);
  const darkSettingsListBackground = CupertinoColors.black;

  const lightSettingSectionColor = CupertinoColors.white;
  const darkSettingSectionColor = Color.fromARGB(255, 28, 28, 30);

  const lightSettingsTitleColor = Color.fromRGBO(109, 109, 114, 1);
  const darkSettingsTitleColor = CupertinoColors.systemGrey;

  const lightDividerColor = Color.fromARGB(255, 238, 238, 238);
  const darkDividerColor = Color.fromARGB(255, 40, 40, 42);

  const lightTrailingTextColor = Color.fromARGB(255, 138, 138, 142);
  const darkTrailingTextColor = Color.fromARGB(255, 152, 152, 159);

  const lightTileHighlightColor = Color.fromARGB(255, 209, 209, 214);
  const darkTileHighlightColor = Color.fromARGB(255, 58, 58, 60);

  const lightSettingsTileTextColor = CupertinoColors.black;
  const darkSettingsTileTextColor = CupertinoColors.white;

  const lightLeadingIconsColor = CupertinoColors.inactiveGray;
  const darkLeadingIconsColor = CupertinoColors.inactiveGray;

  final isLight = brightness == Brightness.light;

  final listBackground =
      isLight ? lightSettingsListBackground : darkSettingsListBackground;

  final sectionBackground =
      isLight ? lightSettingSectionColor : darkSettingSectionColor;

  final titleTextColor =
      isLight ? lightSettingsTitleColor : darkSettingsTitleColor;

  final settingsTileTextColor =
      isLight ? lightSettingsTileTextColor : darkSettingsTileTextColor;

  final dividerColor = isLight ? lightDividerColor : darkDividerColor;

  final trailingTextColor =
      isLight ? lightTrailingTextColor : darkTrailingTextColor;

  final tileHighlightColor =
      isLight ? lightTileHighlightColor : darkTileHighlightColor;

  final leadingIconsColor =
      isLight ? lightLeadingIconsColor : darkLeadingIconsColor;

  return SettingsThemeData(
    tileHighlightColor: tileHighlightColor,
    settingsListBackground: listBackground,
    settingsSectionBackground: sectionBackground,
    titleTextColor: titleTextColor,
    dividerColor: dividerColor,
    trailingTextColor: trailingTextColor,
    settingsTileTextColor: settingsTileTextColor,
    leadingIconsColor: leadingIconsColor,
    inactiveTitleColor: CupertinoColors.inactiveGray,
    inactiveSubtitleColor: CupertinoColors.inactiveGray,
  );
}

SettingsThemeData _webTheme({
  required BuildContext context,
  required Brightness brightness,
}) {
  const lightLeadingIconsColor = Color.fromARGB(255, 70, 70, 70);
  const darkLeadingIconsColor = Color.fromARGB(255, 197, 197, 197);

  const lightSettingsListBackground = Color.fromRGBO(240, 240, 240, 1);
  //done
  const darkSettingsListBackground = Color.fromRGBO(32, 33, 36, 1);

  const lightSettingSectionColor = CupertinoColors.white;
  //done
  const darkSettingSectionColor = Color(0xFF292a2d);

  const lightSettingsTitleColor = Color.fromRGBO(11, 87, 208, 1);
  //done
  const darkSettingsTitleColor = Color.fromRGBO(232, 234, 237, 1);

  const lightTileHighlightColor = Color.fromARGB(255, 220, 220, 220);
  const darkTileHighlightColor = Color.fromARGB(255, 46, 46, 46);

  const lightSettingsTileTextColor = Color.fromARGB(255, 27, 27, 27);
  //done
  const darkSettingsTileTextColor = Color.fromARGB(232, 234, 237, 240);

  const lightTileDescriptionTextColor = Color.fromARGB(255, 70, 70, 70);
  const darkTileDescriptionTextColor = Color.fromARGB(154, 160, 166, 198);

  final isLight = brightness == Brightness.light;

  final listBackground =
      isLight ? lightSettingsListBackground : darkSettingsListBackground;

  final titleTextColor =
      isLight ? lightSettingsTitleColor : darkSettingsTitleColor;

  final settingsTileTextColor =
      isLight ? lightSettingsTileTextColor : darkSettingsTileTextColor;

  final tileHighlightColor =
      isLight ? lightTileHighlightColor : darkTileHighlightColor;

  final tileDescriptionTextColor =
      isLight ? lightTileDescriptionTextColor : darkTileDescriptionTextColor;

  final leadingIconsColor =
      isLight ? lightLeadingIconsColor : darkLeadingIconsColor;

  final sectionBackground =
      isLight ? lightSettingSectionColor : darkSettingSectionColor;

  return SettingsThemeData(
    tileHighlightColor: tileHighlightColor,
    settingsListBackground: listBackground,
    titleTextColor: titleTextColor,
    settingsSectionBackground: sectionBackground,
    settingsTileTextColor: settingsTileTextColor,
    tileDescriptionTextColor: tileDescriptionTextColor,
    leadingIconsColor: leadingIconsColor,
  );
}
