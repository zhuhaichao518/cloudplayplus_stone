#include <fcntl.h>
#include <linux/joystick.h>
#include <unistd.h>
#include <cstdio>

#include <cstring>
#include <functional>
#include <iostream>
#include <string>

#include "gamepad.h"
#include "utils.h"

using namespace gamepad;

/**
 * Reads a joystick event from the joystick gamepad_id.
 *
 * Returns 0 on success. Otherwise -1 is returned.
 */
static int read_event(int fd, struct js_event* event) {
  ssize_t bytes;

  bytes = read(fd, event, sizeof(*event));

  if (bytes == sizeof(*event)) {
    return 0;
  }

  /* Error, could not read full event. */
  return -1;
}

namespace gamepad {
std::optional<GamepadInfo> get_gamepad_info(const std::string& device_id) {
  std::cout << "Listening to gamepad " << device_id << std::endl;

  int file_descriptor = open(device_id.c_str(), O_RDONLY);
  if (file_descriptor == -1) {
    std::cerr << "Could not open joystick: " << file_descriptor << std::endl;
    return std::nullopt;
  }

  char name[128];
  if (ioctl(file_descriptor, JSIOCGNAME(sizeof(name)), name) < 0) {
    std::cerr << "Failed to get joystick name: " << strerror(errno)
              << std::endl;
    strcpy(name, "Unknown");
  }

  return {{device_id, name, file_descriptor, true}};
}

void listen(GamepadInfo* gamepad,
            const std::function<void(const js_event&)>& event_consumer) {
  std::cout << "Listening to gamepad " << gamepad->device_id << std::endl;

  while (gamepad->alive) {
    struct js_event event;
    read_event(gamepad->file_descriptor, &event);
    event_consumer(event);
  }

  std::cout << "Stopped listening for events: " << gamepad->device_id
            << std::endl;
  close(gamepad->file_descriptor);
}
}  // namespace gamepad