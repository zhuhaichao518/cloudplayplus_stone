import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconBuilder{
   static Icon findIconByName(String name){
    if (name == 'Windows'){
      return const Icon(
        FontAwesomeIcons.windows,
        size: 20.0,
      );
    }
    if (name == 'MacOS' || name == 'IOS'){
      return const Icon(
        FontAwesomeIcons.apple,
        size: 20.0,
      );
    }
    if (name == 'Android'){
      return const Icon(
        FontAwesomeIcons.android,
        size: 20.0,
      );
    }
    if (name == 'Linux'){
      return const Icon(
        FontAwesomeIcons.linux,
        size: 20.0,
      );
    }
    if (name == 'Web'){
      return const Icon(
        Icons.web,
        size: 20.0,
      );
    }

    return const Icon(Icons.mobile_off,size:20);
   } 
}