// ignore_for_file: constant_identifier_names
import 'package:flutter_webrtc/flutter_webrtc.dart';

// [--message definitions--]
// 消息设计.md
const int LP_PING = 0;
const int RP_PING = 0;
const int RP_PONG = 1;
const int LP_MOUSE = 1 << 1;
const int LP_DISCONNECT = 1 << 7;
// [--end of message definitions--]

class RTCMessage {
  static bool isEqual(
      RTCDataChannelMessage message1, RTCDataChannelMessage message2) {
    if (message1.isBinary && message2.isBinary) {
      if (message1.binary.length != message2.binary.length) {
        return false;
      }
      for (int i = 0; i < message1.binary.length; i++) {
        if (message1.binary[i] != message2.binary[i]) {
          return false;
        }
      }
      return true;
    } else if (!message1.isBinary && !message2.isBinary) {
      if (message1.text == message2.text) {
        return true;
      }
    }
    return false;
  }
}
