#ifndef FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "gamepad.h"

namespace gamepads_windows {

class GamepadsWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  GamepadsWindowsPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~GamepadsWindowsPlugin();

  // Disallow copy and assign.
  GamepadsWindowsPlugin(const GamepadsWindowsPlugin&) = delete;
  GamepadsWindowsPlugin& operator=(const GamepadsWindowsPlugin&) = delete;

 private:
  flutter::PluginRegistrarWindows* registrar;
  static inline std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel{};

  int window_proc_id = -1;
  HDEVNOTIFY hDevNotify;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void emit_gamepad_event(Gamepad* gamepad, const Event& event);
};

}  // namespace gamepads_windows

#endif  // FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_
