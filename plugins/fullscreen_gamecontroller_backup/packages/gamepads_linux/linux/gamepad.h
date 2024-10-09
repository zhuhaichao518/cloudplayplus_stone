#include <fcntl.h>
#include <linux/joystick.h>
#include <unistd.h>

#include <functional>
#include <optional>
#include <string>

#include "utils.h"

namespace gamepad {
struct GamepadInfo {
  std::string device_id;
  std::string name;
  int file_descriptor;
  bool alive;
};

std::optional<GamepadInfo> get_gamepad_info(const std::string& device);

void listen(GamepadInfo* gamepad,
            const std::function<void(const js_event&)>& event_consumer);
}  // namespace gamepad