import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/sections/abstract_settings_section.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/utils/platform_utils.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/utils/settings_theme.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/src/utils/theme_provider.dart';

enum ApplicationType {
  /// Use this parameter is you are using the MaterialApp
  material,

  /// Use this parameter is you are using the CupertinoApp
  cupertino,

  /// Use this parameter is you are using the MaterialApp for Android
  /// and the CupertinoApp for iOS.
  both,
}

class SettingsList extends StatelessWidget {
  const SettingsList({
    required this.sections,
    this.shrinkWrap = false,
    this.physics,
    this.platform,
    this.lightTheme,
    this.darkTheme,
    this.brightness,
    this.contentPadding,
    this.applicationType = ApplicationType.material,
    Key? key,
  }) : super(key: key);

  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final DevicePlatform? platform;
  final SettingsThemeData? lightTheme;
  final SettingsThemeData? darkTheme;
  final Brightness? brightness;
  final EdgeInsetsGeometry? contentPadding;
  final List<AbstractSettingsSection> sections;
  final ApplicationType applicationType;

  @override
  Widget build(BuildContext context) {
    DevicePlatform platform;
    if (this.platform == null || this.platform == DevicePlatform.device) {
      platform = detectPlatform(context);
    } else {
      platform = this.platform!;
    }

    final brightness = calculateBrightness(context);

    final themeData = getTheme(
      context: context,
      platform: platform,
      brightness: brightness,
    ).merge(theme: brightness == Brightness.dark ? darkTheme : lightTheme);

    return Container(
      color: themeData.settingsListBackground,
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, layout) {
          return SettingsTheme(
            themeData: themeData,
            platform: platform,
            child: ListView.builder(
              physics: physics,
              shrinkWrap: shrinkWrap,
              itemCount: sections.length,
              padding: contentPadding ??
                  calculateDefaultPadding(platform, layout.maxWidth),
              itemBuilder: (BuildContext context, int index) {
                return sections[index];
              },
            ),
          );
        },
      ),
    );
  }

  EdgeInsets calculateDefaultPadding(
    DevicePlatform platform,
    double width,
  ) {
    if (width > 810) {
      final padding = (width - 810) / 2;
      switch (platform) {
        case DevicePlatform.web:
          return EdgeInsets.symmetric(vertical: 20, horizontal: padding);
        case DevicePlatform.device:
          throw Exception(
            "You can't use the DevicePlatform.device in this context. "
            'Incorrect platform: SettingsList.calculateDefaultPadding',
          );
        case DevicePlatform.android:
        case DevicePlatform.fuchsia:
        case DevicePlatform.linux:
        case DevicePlatform.iOS:
        case DevicePlatform.macOS:
        case DevicePlatform.windows:
        default:
          return EdgeInsets.symmetric(
            horizontal: padding,
          );
      }
    }

    switch (platform) {
      case DevicePlatform.android:
      case DevicePlatform.fuchsia:
      case DevicePlatform.linux:
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
      case DevicePlatform.windows:
        return EdgeInsets.zero;
      case DevicePlatform.web:
        return const EdgeInsets.symmetric(vertical: 20);
      case DevicePlatform.device:
        throw Exception(
          "You can't use the DevicePlatform.device in this context. "
          'Incorrect platform: SettingsList.calculateDefaultPadding',
        );
    }
  }

  Brightness calculateBrightness(BuildContext context) {
    final materialBrightness = Theme.of(context).brightness;
    final cupertinoBrightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.of(context).platformBrightness;

    switch (applicationType) {
      case ApplicationType.material:
        return materialBrightness;
      case ApplicationType.cupertino:
        return cupertinoBrightness;
      case ApplicationType.both:
        return platform != DevicePlatform.iOS
            ? materialBrightness
            : cupertinoBrightness;
    }
  }
}
