#include <unistd.h>
#include <functional>
#include <iostream>
#include <optional>
#include <string>

#include <dirent.h>
#include <sys/inotify.h>
#include <map>

#include "connection_listener.h"
#include "utils.h"

using namespace connection_listener;

const std::string _input_dir = "/dev/input/";

std::map<ConnectionEventType, const char*> connectionEventTypeNames = {
    {ConnectionEventType::CONNECTED, "CONNECTED"},
    {ConnectionEventType::DISCONNECTED, "DISCONNECTED"},
};

std::optional<ConnectionEventType> _parseEventType(inotify_event* event) {
  uint mask = event->mask;
  if ((mask & IN_CREATE) || (mask & IN_ATTRIB)) {
    return ConnectionEventType::CONNECTED;
  } else if (mask & IN_DELETE) {
    return ConnectionEventType::DISCONNECTED;
  } else {
    return std::nullopt;
  }
}

void _list_existing(
    const std::function<void(const ConnectionEvent&)>& event_consumer) {
  DIR* dir = opendir(_input_dir.c_str());

  if (!dir) {
    std::cerr << "Failed to open directory: " << _input_dir << std::endl;
    throw std::runtime_error("Error reading existing connections");
  }

  struct dirent* entry;
  std::vector<std::string> devices;
  while ((entry = readdir(dir)) != nullptr) {
    if (entry->d_type != DT_CHR) {
      continue;
    }
    if (!starts_with(entry->d_name, "js")) {
      continue;
    }
    std::string device = _input_dir + entry->d_name;
    devices.push_back(device);
  }

  closedir(dir);

  for (std::string& device : devices) {
    ConnectionEvent connectionEvent = {ConnectionEventType::CONNECTED, device};
    event_consumer(connectionEvent);
  }
}

void _wait_for_connections(
    int inotify,
    const std::function<void(const ConnectionEvent&)>& event_consumer) {
  char buffer[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
  ssize_t len = read(inotify, buffer, sizeof(buffer));
  if (len < 0) {
    std::cerr << "Error reading inotify events" << std::endl;
    throw std::runtime_error("Error reading inotify events");
  }

  char* ptr = buffer;
  while (ptr < buffer + len) {
    auto* event = reinterpret_cast<struct inotify_event*>(ptr);
    std::string name = event->name;
    if (!starts_with(name, "js")) {
      break;
    }

    std::string device = _input_dir + name;
    std::optional<ConnectionEventType> type = _parseEventType(event);

    std::cout << "Connection found: " << connectionEventTypeNames[*type]
              << " - " << name << std::endl;
    ConnectionEvent connection_event = {*type, device};
    event_consumer(connection_event);

    ptr += sizeof(struct inotify_event) + event->len;
  }
}

namespace connection_listener {
void listen(const bool* keep_reading,
            const std::function<void(const ConnectionEvent&)>& event_consumer) {
  std::cout << "Reading initial gamepads..." << std::endl;
  _list_existing(event_consumer);

  int inotify = inotify_init();
  if (inotify == -1) {
    std::cerr << "Error initializing inotify" << std::endl;
    throw std::runtime_error("Error initializing inotify");
  }
  int watcher = inotify_add_watch(inotify, _input_dir.c_str(),
                                  IN_CREATE | IN_DELETE | IN_ATTRIB);
  if (watcher == -1) {
    close(inotify);
    std::cerr << "Error adding watch for " << _input_dir << std::endl;
    throw std::runtime_error("Error adding inotify watch");
  }

  std::cout << "Listening for gamepads..." << std::endl;
  while (*keep_reading) {
    _wait_for_connections(inotify, event_consumer);
  }
  std::cout << "Stopped listening for gamepads." << std::endl;

  // Remove the inotify watch and close the file descriptor
  inotify_rm_watch(inotify, watcher);
  close(inotify);
}
}  // namespace connection_listener