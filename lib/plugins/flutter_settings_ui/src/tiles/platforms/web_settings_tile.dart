import 'package:flutter/material.dart';
import 'package:cloudplayplus/plugins/flutter_settings_ui/flutter_settings_ui.dart';

class WebSettingsTile extends StatelessWidget {
  const WebSettingsTile({
    required this.tileType,
    required this.leading,
    required this.title,
    required this.description,
    required this.onPressed,
    required this.onToggle,
    required this.value,
    required this.initialValue,
    required this.activeSwitchColor,
    required this.enabled,
    required this.trailing,
    Key? key,
  }) : super(key: key);

  final SettingsTileType tileType;
  final Widget? leading;
  final Widget? title;
  final Widget? description;
  final Function(BuildContext context)? onPressed;
  final Function(bool value)? onToggle;
  final Widget? value;
  final bool initialValue;
  final bool enabled;
  final Widget? trailing;
  final Color? activeSwitchColor;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    // final scaleFactor = MediaQuery.of(context).textScaleFactor;
    final scaleFactor = MediaQuery.textScalerOf(context).scale(1);

    final cantShowAnimation = tileType == SettingsTileType.switchTile
        ? onToggle == null && onPressed == null
        : onPressed == null;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cantShowAnimation
              ? null
              : () {
                  if (tileType == SettingsTileType.switchTile) {
                    onToggle?.call(!initialValue);
                  } else {
                    onPressed?.call(context);
                  }
                },
          highlightColor: theme.themeData.tileHighlightColor,
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 24,
                  ),
                  child: IconTheme(
                    data: IconTheme.of(context).copyWith(
                      color: theme.themeData.leadingIconsColor,
                    ),
                    child: leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 24,
                    end: 24,
                    bottom: 19 * scaleFactor,
                    top: 19 * scaleFactor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: TextStyle(
                          color: theme.themeData.settingsTileTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        child: title ?? Container(),
                      ),
                      if (value != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: theme.themeData.tileDescriptionTextColor,
                            ),
                            child: value!,
                          ),
                        )
                      else if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: theme.themeData.tileDescriptionTextColor,
                            ),
                            child: description!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // if (tileType == SettingsTileType.navigationTile)
              //   Padding(
              //     padding:
              //         const EdgeInsetsDirectional.only(start: 6, end: 15),
              //     child: IconTheme(
              //       data: IconTheme.of(context)
              //           .copyWith(color: theme.themeData.leadingIconsColor),
              //       child: Icon(
              //         CupertinoIcons.chevron_forward,
              //         size: 18 * scaleFactor,
              //       ),
              //     ),
              //   ),
              if (trailing != null && tileType == SettingsTileType.switchTile)
                Row(
                  children: [
                    trailing!,
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Switch(
                        activeColor: activeSwitchColor ??
                            const Color.fromRGBO(138, 180, 248, 1.0),
                        value: initialValue,
                        onChanged: onToggle,
                      ),
                    ),
                  ],
                )
              else if (tileType == SettingsTileType.switchTile)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                  child: Switch(
                    value: initialValue,
                    activeColor: activeSwitchColor ??
                        const Color.fromRGBO(138, 180, 248, 1.0),
                    onChanged: onToggle,
                  ),
                )
              else if (trailing != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
