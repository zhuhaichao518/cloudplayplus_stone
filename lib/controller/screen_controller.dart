import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

//Manage which screens will be shown.
class ScreenController {
  //isFullScreen means borderless occupy the whole device screen.
  static bool isFullScreen = false;
  //onlyShowRemoteScreen means show nothing except the 
  //remote desktop. This means the buttom navigation bar and appbar, master page will not be shown.
  static bool onlyShowRemoteScreen = false;


  static Future<void> setIsFullScreen(bool isFullScreen) async{
    if (ScreenController.isFullScreen == isFullScreen) return;
    if (AppPlatform.isWeb){
      if (isFullScreen) {
        //Planning to add to WindowManager.
        //window.document.documentElement?.requestFullscreen();
      } else {
        //window.document.exitFullscreen();
      }
    }
    if (AppPlatform.isDeskTop){
        await windowManager.setFullScreen(isFullScreen);
    }
    ScreenController.isFullScreen = isFullScreen;
  }

  static void setOnlyShowRemoteScreen(bool occupyScreen){
  
  }

  static Future<void> initialize() async{
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();
  }
}
