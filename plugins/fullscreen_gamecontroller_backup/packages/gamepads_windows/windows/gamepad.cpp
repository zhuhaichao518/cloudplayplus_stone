#include <iostream>
#define WIN32_LEAN_AND_MEAN
#include <dbt.h>
#include <hidclass.h>
#include <initguid.h>
#include <windows.h>
#pragma comment(lib, "winmm.lib")
#include <mmsystem.h>

#include <list>
#include <map>
#include <optional>
#include <set>
#include <thread>

#include "gamepad.h"
#include "utils.h"

Gamepads gamepads;

std::list<Event> Gamepads::diff_states(Gamepad* gamepad,
                                       const JOYINFOEX& old,
                                       const JOYINFOEX& current) {
  std::time_t now = std::time(nullptr);
  int time = static_cast<int>(now);

  std::list<Event> events;
  if (old.dwXpos != current.dwXpos) {
    events.push_back(
        {time, "analog", "dwXpos", static_cast<int>(current.dwXpos)});
  }
  if (old.dwYpos != current.dwYpos) {
    events.push_back(
        {time, "analog", "dwYpos", static_cast<int>(current.dwYpos)});
  }
  if (old.dwZpos != current.dwZpos) {
    events.push_back(
        {time, "analog", "dwZpos", static_cast<int>(current.dwZpos)});
  }
  if (old.dwRpos != current.dwRpos) {
    events.push_back(
        {time, "analog", "dwRpos", static_cast<int>(current.dwRpos)});
  }
  if (old.dwUpos != current.dwUpos) {
    events.push_back(
        {time, "analog", "dwUpos", static_cast<int>(current.dwUpos)});
  }
  if (old.dwVpos != current.dwVpos) {
    events.push_back(
        {time, "analog", "dwVpos", static_cast<int>(current.dwVpos)});
  }
  if (old.dwPOV != current.dwPOV) {
    events.push_back({time, "analog", "pov", static_cast<int>(current.dwPOV)});
  }
  if (old.dwButtons != current.dwButtons) {
    for (int i = 0; i < gamepad->num_buttons; ++i) {
      bool was_pressed = old.dwButtons & (1 << i);
      bool is_pressed = current.dwButtons & (1 << i);
      if (was_pressed != is_pressed) {
        events.push_back(
            {time, "button", "button-" + std::to_string(i), is_pressed});
      }
    }
  }
  return events;
}

bool Gamepads::are_states_different(const JOYINFOEX& a, const JOYINFOEX& b) {
  return a.dwXpos != b.dwXpos || a.dwYpos != b.dwYpos || a.dwZpos != b.dwZpos ||
         a.dwRpos != b.dwRpos || a.dwUpos != b.dwUpos || a.dwVpos != b.dwVpos ||
         a.dwButtons != b.dwButtons || a.dwPOV != b.dwPOV;
}

void Gamepads::read_gamepad(Gamepad* gamepad) {
  JOYINFOEX state;
  state.dwSize = sizeof(JOYINFOEX);
  state.dwFlags = JOY_RETURNALL;

  int joy_id = gamepad->joy_id;

  std::cout << "Listening to gamepad " << joy_id << std::endl;

  while (gamepad->alive) {
    JOYINFOEX previous_state = state;
    MMRESULT result = joyGetPosEx(joy_id, &state);
    if (result == JOYERR_NOERROR) {
      if (are_states_different(previous_state, state)) {
        std::list<Event> events = diff_states(gamepad, previous_state, state);
        for (auto joy_event : events) {
          if (event_emitter.has_value()) {
            (*event_emitter)(gamepad, joy_event);
          }
        }
      }
    } else {
      std::cout << "Fail to listen to gamepad " << joy_id << std::endl;
      gamepad->alive = false;
      gamepads.erase(joy_id);
    }
  }
}

void Gamepads::connect_gamepad(UINT joy_id, std::string name, int num_buttons) {
  gamepads[joy_id] = {joy_id, name, num_buttons, true};
  std::thread read_thread(
      [this, joy_id]() { read_gamepad(&gamepads[joy_id]); });
  read_thread.detach();
}

void Gamepads::update_gamepads() {
  std::cout << "Updating gamepads..." << std::endl;
  UINT max_joysticks = joyGetNumDevs();
  JOYCAPSW joy_caps;
  for (UINT joy_id = 0; joy_id < max_joysticks; ++joy_id) {
    MMRESULT result = joyGetDevCapsW(joy_id, &joy_caps, sizeof(JOYCAPSW));
    if (result == JOYERR_NOERROR) {
      std::string name = to_string(joy_caps.szPname);
      int num_buttons = static_cast<int>(joy_caps.wNumButtons);
      std::optional<Gamepad> gamepad = gamepads[joy_id];
      if (gamepad) {
        if (gamepad->name != name) {
          std::cout << "Updated gamepad " << joy_id << std::endl;
          gamepad->alive = false;
          gamepads.erase(joy_id);

          connect_gamepad(joy_id, name, num_buttons);
        }
      } else {
        std::cout << "New gamepad connected " << joy_id << std::endl;
        connect_gamepad(joy_id, name, num_buttons);
      }
    }
  }
}

std::set<std::wstring> connected_devices;

LRESULT CALLBACK GamepadListenerProc(HWND hwnd,
                                     UINT uMsg,
                                     WPARAM wParam,
                                     LPARAM lParam) {
  switch (uMsg) {

    /*case WM_DEVICECHANGE: {
      if (lParam != NULL) {
        PDEV_BROADCAST_HDR pHdr = (PDEV_BROADCAST_HDR)lParam;
        if (pHdr->dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE) {
          PDEV_BROADCAST_DEVICEINTERFACE pDevInterface =
              (PDEV_BROADCAST_DEVICEINTERFACE)pHdr;
          if (IsEqualGUID(pDevInterface->dbcc_classguid,
                          GUID_DEVINTERFACE_HID)) {
            std::wstring device_path = pDevInterface->dbcc_name;
            bool is_connected =
                connected_devices.find(device_path) != connected_devices.end();
            if (!is_connected && wParam == DBT_DEVICEARRIVAL) {
              connected_devices.insert(device_path);
              gamepads.update_gamepads();
            } else if (is_connected && wParam == DBT_DEVICEREMOVECOMPLETE) {
              connected_devices.erase(device_path);
              gamepads.update_gamepads();
            }
          }
        }
      }
      return 0;
    }*/
    case WM_DESTROY: {
      PostQuitMessage(0);
      return 0;
    }
    default: {
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
  }
}
