#include <string>

bool starts_with(const std::string& str, const std::string& prefix) {
  if (prefix.length() > str.length()) {
    return false;
  }
  return str.compare(0, prefix.length(), prefix) == 0;
}