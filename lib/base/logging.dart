import 'package:flutter/foundation.dart';
import '../dev_settings.dart/develop_settings.dart';

// ignore: non_constant_identifier_names
void VLOG0(Object s) {
  if (DevelopSettings.isDebugging) {
    print(s);
  }
}
