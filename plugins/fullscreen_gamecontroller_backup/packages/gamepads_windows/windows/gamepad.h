#include <windows.h>
#include <functional>
#include <iostream>
#include <list>
#include <map>

struct Gamepad {
  UINT joy_id;
  std::string name;
  int num_buttons;
  bool alive;
};

struct Event {
  int time;
  std::string type;
  std::string key;
  int value;
};

class Gamepads {
 private:
  std::list<Event> diff_states(Gamepad* gamepad,
                               const JOYINFOEX& old,
                               const JOYINFOEX& current);
  bool are_states_different(const JOYINFOEX& a, const JOYINFOEX& b);
  void read_gamepad(Gamepad* gamepad);
  void connect_gamepad(UINT joy_id, std::string name, int num_buttons);

 public:
  std::map<UINT, Gamepad> gamepads;
  std::optional<std::function<void(Gamepad* gamepad, const Event& event)>>
      event_emitter;
  void update_gamepads();
};

extern Gamepads gamepads;

LRESULT CALLBACK GamepadListenerProc(HWND hwnd,
                                     UINT uMsg,
                                     WPARAM wParam,
                                     LPARAM lParam);