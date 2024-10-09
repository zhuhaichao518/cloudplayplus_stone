#include "gamepads_windows_plugin.h"

#include <dbt.h>
#include <hidclass.h>
#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace gamepads_windows {
void GamepadsWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "haichaoz/gamepads",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<GamepadsWindowsPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

GamepadsWindowsPlugin::GamepadsWindowsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar(registrar) {
  gamepads.event_emitter = [&](Gamepad* gamepad, const Event& event) {
    this->emit_gamepad_event(gamepad, event);
  };
  gamepads.update_gamepads();
  window_proc_id = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        DEV_BROADCAST_DEVICEINTERFACE filter = {};
        filter.dbcc_size = sizeof(filter);
        filter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
        filter.dbcc_classguid = GUID_DEVINTERFACE_HID;
        this->hDevNotify = RegisterDeviceNotification(
            hwnd, &filter, DEVICE_NOTIFY_WINDOW_HANDLE);

        return GamepadListenerProc(hwnd, message, wparam, lparam);
      });
}

GamepadsWindowsPlugin::~GamepadsWindowsPlugin() {
  UnregisterDeviceNotification(hDevNotify);
  registrar->UnregisterTopLevelWindowProcDelegate(window_proc_id);
}

void GamepadsWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("listGamepads") == 0) {
    flutter::EncodableList list;
    for (auto [device_id, gamepad] : gamepads.gamepads) {
      flutter::EncodableMap map;
      map[flutter::EncodableValue("id")] =
          flutter::EncodableValue(std::to_string(device_id));
      map[flutter::EncodableValue("name")] =
          flutter::EncodableValue(gamepad.name);
      list.push_back(flutter::EncodableValue(map));
    }
    result->Success(flutter::EncodableValue(list));
  } else {
    result->NotImplemented();
  }
}

void GamepadsWindowsPlugin::emit_gamepad_event(Gamepad* gamepad,
                                               const Event& event) {
  auto _channel = this->channel.get();
  if (_channel) {
    flutter::EncodableMap map;
    map[flutter::EncodableValue("gamepadId")] =
        flutter::EncodableValue(std::to_string(gamepad->joy_id));
    map[flutter::EncodableValue("time")] = flutter::EncodableValue(event.time);
    map[flutter::EncodableValue("type")] = flutter::EncodableValue(event.type);
    map[flutter::EncodableValue("key")] = flutter::EncodableValue(event.key);
    map[flutter::EncodableValue("value")] =
        flutter::EncodableValue(static_cast<double>(event.value));
    _channel->InvokeMethod("onGamepadEvent",
                           std::make_unique<flutter::EncodableValue>(
                               flutter::EncodableValue(map)));
  }
}
}  // namespace gamepads_windows
