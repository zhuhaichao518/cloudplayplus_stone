#include "include/gamepads_windows/gamepads_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "gamepads_windows_plugin.h"

void GamepadsWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  gamepads_windows::GamepadsWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
