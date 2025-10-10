import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fullscreen_window/fullscreen_window.dart';


//Manage which screens will be shown.
class ScreenController {
  //isFullScreen means borderless occupy the whole device screen.
  static bool isFullScreen = false;
  //onlyShowRemoteScreen means show nothing except the
  //remote desktop. This means the buttom navigation bar and appbar, master page will not be shown.
  static bool onlyShowRemoteScreen = false;

  static ValueNotifier<bool> showBottomNav = ValueNotifier(true);

  //Flutter's default height of bottomNavHeight.
  static double bottomNavHeight = kBottomNavigationBarHeight;

  static void setShowNavBar(bool value) {
    showBottomNav.value = value;
  }

  static ValueNotifier<bool> showMasterList = ValueNotifier(true);

  static void setShowMasterList(bool value) {
    showMasterList.value = value;
  }

  static ValueNotifier<bool> showDetailUseScrollView = ValueNotifier(false);
  static void setshowDetailUseScrollView(bool value) {
    if (showDetailUseScrollView.value != value) {
      showDetailUseScrollView.value = value;
    }
  }

  static ValueNotifier<bool> showDetailTitle = ValueNotifier(true);
  static double detailTitleHeight = 56;

  static void setShowDetailTitle(bool value) {
    if (showDetailTitle.value != value) {
      showDetailTitle.value = value;
    }
  }

  static ValueNotifier<bool> showVirtualKeyboard = ValueNotifier(false);
  static void setShowVirtualKeyboard(bool value) {
    if (showVirtualKeyboard.value != value) {
      showVirtualKeyboard.value = value;
    }
  }

  static ValueNotifier<bool> showVirtualGamePad = ValueNotifier(false);
  static void setshowVirtualGamePad(bool value) {
    if (showVirtualGamePad.value != value) {
      showVirtualGamePad.value = value;
    }
  }

  static ValueNotifier<bool> showVirtualMouse = ValueNotifier(false);
  
  static ValueNotifier<bool> showVideoInfo = ValueNotifier(false);
  static void setShowVideoInfo(bool value) {
    if (showVideoInfo.value != value) {
      showVideoInfo.value = value;
    }
  }

  static void setShowVirtualMouse(bool value) {
    if (showVirtualMouse.value != value) {
      showVirtualMouse.value = value;
    }
  }

  //1: Expand To Width
  //2: Expand to Both
  /*static ValueNotifier<int> detailViewExpandMode = ValueNotifier(1);
  static void setDetailViewExpandMode(int value){
    if (detailViewExpandMode.value != value) {
      detailViewExpandMode.value = value;
    }
  }*/
  static bool videoRendererExpandToWidth = false;

  static double videoHeight = 768;

  static Future<void> setIsFullScreen(bool isFullScreen) async {
    if (ScreenController.isFullScreen == isFullScreen) return;
    if (AppPlatform.isDeskTop) {
      await windowManager.setFullScreen(isFullScreen);
    } else {
      await FullScreenWindow.setFullScreen(isFullScreen);
    }
    ScreenController.isFullScreen = isFullScreen;
  }

  static void showButtomNavigationBar(bool showNavigationBar) {
    if (ScreenController.showBottomNav.value == showNavigationBar) return;
    ScreenController.showBottomNav.value = showNavigationBar;
  }

  static void setOnlyShowRemoteScreen(bool occupyScreen) {
    if (ScreenController.onlyShowRemoteScreen == occupyScreen) return;
    setShowNavBar(!occupyScreen);
    //Master_detail
    setShowMasterList(!occupyScreen);
    setShowDetailTitle(!occupyScreen);
    ScreenController.onlyShowRemoteScreen = occupyScreen;
  }

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    if (AppPlatform.isDeskTop) {
      await windowManager.ensureInitialized();
    }
  }
}
