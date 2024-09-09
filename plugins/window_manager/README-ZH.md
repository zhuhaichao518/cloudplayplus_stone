# window_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] [![All Contributors][all-contributors-image]](#contributors)

[pub-image]: https://img.shields.io/pub/v/window_manager.svg
[pub-url]: https://pub.dev/packages/window_manager

[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

[all-contributors-image]: https://img.shields.io/github/all-contributors/leanflutter/window_manager?color=ee8449&style=flat-square

这个插件允许 Flutter 桌面应用调整窗口的大小和位置。

---

[English](./README.md) | 简体中文

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [平台支持](#%E5%B9%B3%E5%8F%B0%E6%94%AF%E6%8C%81)
- [快速开始](#%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B)
  - [安装](#%E5%AE%89%E8%A3%85)
  - [用法](#%E7%94%A8%E6%B3%95)
    - [监听事件](#%E7%9B%91%E5%90%AC%E4%BA%8B%E4%BB%B6)
    - [关闭时退出](#%E5%85%B3%E9%97%AD%E6%97%B6%E9%80%80%E5%87%BA)
      - [macOS](#macos)
    - [关闭前确认](#%E5%85%B3%E9%97%AD%E5%89%8D%E7%A1%AE%E8%AE%A4)
    - [在启动时隐藏](#%E5%9C%A8%E5%90%AF%E5%8A%A8%E6%97%B6%E9%9A%90%E8%97%8F)
      - [Linux](#linux)
      - [macOS](#macos-1)
      - [Windows](#windows)
- [文章](#%E6%96%87%E7%AB%A0)
- [谁在用使用它？](#%E8%B0%81%E5%9C%A8%E7%94%A8%E4%BD%BF%E7%94%A8%E5%AE%83)
- [API](#api)
  - [WindowManager](#windowmanager)
    - [Methods](#methods)
      - [waitUntilReadyToShow](#waituntilreadytoshow)
      - [destroy](#destroy)
      - [close](#close)
      - [isPreventClose](#ispreventclose)
      - [setPreventClose](#setpreventclose)
      - [focus](#focus)
      - [blur  `macos`  `windows`](#blur--macos--windows)
      - [isFocused  `macos`  `windows`](#isfocused--macos--windows)
      - [show](#show)
      - [hide](#hide)
      - [isVisible](#isvisible)
      - [isMaximized](#ismaximized)
      - [maximize](#maximize)
      - [unmaximize](#unmaximize)
      - [isMinimized](#isminimized)
      - [minimize](#minimize)
      - [restore](#restore)
      - [isFullScreen](#isfullscreen)
      - [setFullScreen](#setfullscreen)
      - [isDockable  `windows`](#isdockable--windows)
      - [isDocked  `windows`](#isdocked--windows)
      - [dock  `windows`](#dock--windows)
      - [undock  `windows`](#undock--windows)
      - [setAspectRatio](#setaspectratio)
      - [setBackgroundColor](#setbackgroundcolor)
      - [setAlignment](#setalignment)
      - [center](#center)
      - [getBounds](#getbounds)
      - [setBounds](#setbounds)
      - [getSize](#getsize)
      - [setSize](#setsize)
      - [getPosition](#getposition)
      - [setPosition](#setposition)
      - [setMinimumSize](#setminimumsize)
      - [setMaximumSize](#setmaximumsize)
      - [isResizable](#isresizable)
      - [setResizable](#setresizable)
      - [isMovable  `macos`](#ismovable--macos)
      - [setMovable  `macos`](#setmovable--macos)
      - [isMinimizable  `macos`  `windows`](#isminimizable--macos--windows)
      - [setMinimizable  `macos`  `windows`](#setminimizable--macos--windows)
      - [isClosable  `windows`](#isclosable--windows)
      - [isMaximizable  `macos`  `windows`](#ismaximizable--macos--windows)
      - [setMaximizable](#setmaximizable)
      - [setClosable  `macos`  `windows`](#setclosable--macos--windows)
      - [isAlwaysOnTop](#isalwaysontop)
      - [setAlwaysOnTop](#setalwaysontop)
      - [isAlwaysOnBottom](#isalwaysonbottom)
      - [setAlwaysOnBottom  `linux`  `windows`](#setalwaysonbottom--linux--windows)
      - [getTitle](#gettitle)
      - [setTitle](#settitle)
      - [setTitleBarStyle](#settitlebarstyle)
      - [getTitleBarHeight](#gettitlebarheight)
      - [isSkipTaskbar](#isskiptaskbar)
      - [setSkipTaskbar](#setskiptaskbar)
      - [setProgressBar  `macos`  `windows`](#setprogressbar--macos--windows)
      - [setIcon  `windows`](#seticon--windows)
      - [isVisibleOnAllWorkspaces  `macos`](#isvisibleonallworkspaces--macos)
      - [setVisibleOnAllWorkspaces  `macos`](#setvisibleonallworkspaces--macos)
      - [setBadgeLabel  `macos`](#setbadgelabel--macos)
      - [hasShadow  `macos`  `windows`](#hasshadow--macos--windows)
      - [setHasShadow  `macos`  `windows`](#sethasshadow--macos--windows)
      - [getOpacity](#getopacity)
      - [setOpacity](#setopacity)
      - [setBrightness](#setbrightness)
      - [setIgnoreMouseEvents](#setignoremouseevents)
      - [startDragging](#startdragging)
      - [startResizing  `linux`  `windows`](#startresizing--linux--windows)
      - [grabKeyboard  `linux`](#grabkeyboard--linux)
      - [ungrabKeyboard  `linux`](#ungrabkeyboard--linux)
  - [WindowListener](#windowlistener)
    - [Methods](#methods-1)
      - [onWindowClose](#onwindowclose)
      - [onWindowFocus](#onwindowfocus)
      - [onWindowBlur](#onwindowblur)
      - [onWindowMaximize](#onwindowmaximize)
      - [onWindowUnmaximize](#onwindowunmaximize)
      - [onWindowMinimize](#onwindowminimize)
      - [onWindowRestore](#onwindowrestore)
      - [onWindowResize](#onwindowresize)
      - [onWindowResized  `macos`  `windows`](#onwindowresized--macos--windows)
      - [onWindowMove](#onwindowmove)
      - [onWindowMoved  `macos`  `windows`](#onwindowmoved--macos--windows)
      - [onWindowEnterFullScreen](#onwindowenterfullscreen)
      - [onWindowLeaveFullScreen](#onwindowleavefullscreen)
      - [onWindowDocked  `windows`](#onwindowdocked--windows)
      - [onWindowUndocked  `windows`](#onwindowundocked--windows)
      - [onWindowEvent](#onwindowevent)
- [贡献者](#%E8%B4%A1%E7%8C%AE%E8%80%85)
- [许可证](#%E8%AE%B8%E5%8F%AF%E8%AF%81)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 平台支持

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️   |   ✔️   |    ✔️    |

## 快速开始

### 安装

将此添加到你的软件包的 `pubspec.yaml` 文件：

```yaml
dependencies:
  window_manager: ^0.4.2
```

或

```yaml
dependencies:
  window_manager:
    git:
      url: https://github.com/leanflutter/window_manager.git
      ref: main
```

### 用法

```dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp());
}

```

> 请看这个插件的示例应用，以了解完整的例子。

#### 监听事件

```dart
import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }

  @override
  void onWindowEvent(String eventName) {
    print('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowClose() {
    // do something
  }

  @override
  void onWindowFocus() {
    // do something
  }

  @override
  void onWindowBlur() {
    // do something
  }

  @override
  void onWindowMaximize() {
    // do something
  }

  @override
  void onWindowUnmaximize() {
    // do something
  }

  @override
  void onWindowMinimize() {
    // do something
  }

  @override
  void onWindowRestore() {
    // do something
  }

  @override
  void onWindowResize() {
    // do something
  }

  @override
  void onWindowMove() {
    // do something
  }

  @override
  void onWindowEnterFullScreen() {
    // do something
  }

  @override
  void onWindowLeaveFullScreen() {
    // do something
  }
}
```

#### 关闭时退出

如果你需要使用 `hide` 方法，你需要禁用 `QuitOnClose`。

##### macOS

更改文件 `macos/Runner/AppDelegate.swift` 如下：

```diff
import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
-    return true
+    return false
  }
}
```

#### 关闭前确认

```dart
import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
```

#### 在启动时隐藏

##### Linux

更改文件 `linux/my_application.cc` 如下：

```diff

...

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  
  ...

  gtk_window_set_default_size(window, 1280, 720);
-  gtk_widget_show(GTK_WIDGET(window));
+  gtk_widget_realize(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

...

```

##### macOS

更改文件 `macos/Runner/MainFlutterWindow.swift` 如下：

```diff
import Cocoa
import FlutterMacOS
+import window_manager

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController.init()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }

+    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
+        super.order(place, relativeTo: otherWin)
+        hiddenWindowAtLaunch()
+    }
}

```

##### Windows

更改文件 `windows/runner/win32_window.cpp` 如下：

```diff
bool Win32Window::CreateAndShow(const std::wstring& title,
                                const Point& origin,
                                const Size& size) {
  ...                              
  HWND window = CreateWindow(
-      window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
+      window_class, title.c_str(),
+      WS_OVERLAPPEDWINDOW, // do not add WS_VISIBLE since the window will be shown later
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);
```

使用 flutter 3.7 创建的 Windows 项目
更改 `windows/runner/flutter_window.cpp` 如下:

```diff
bool FlutterWindow::OnCreate() {
  ...
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
-   this->Show();
+   "" //删除 this->Show()
  });
```

确保在 `onWindowFocus` 事件中调用一次 `setState`。

```dart
import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
    // do something
  }
}

```

## 文章

- [关闭窗口后点击Dock图标进行恢复](https://leanflutter.org/zh/blog/click-dock-icon-to-restore-after-closing-the-window)
- [让应用成为单实例](https://leanflutter.org/zh/blog/making-the-app-single-instanced)

## 谁在用使用它？

- [Airclap](https://airclap.app/) - 任何文件，任意设备，随意发送。简单好用的跨平台高速文件传输APP。
- [AuthPass](https://authpass.app/) - 基于Flutter的密码管理器，适用于所有平台。兼容Keepass 2.x（kdbx 3.x）。
- [Biyi (比译)](https://biyidev.com/) - 一个便捷的翻译和词典应用程序。
- [BlueBubbles](https://github.com/BlueBubblesApp/bluebubbles-app) - BlueBubbles is an ecosystem of apps bringing iMessage to Android, Windows, and Linux
- [LunaSea](https://github.com/CometTools/LunaSea) - A self-hosted controller for mobile and macOS built using the Flutter framework.
- [Linwood Butterfly](https://github.com/LinwoodCloud/Butterfly) - 用 Flutter 编写的开源笔记应用
- [RustDesk](https://github.com/rustdesk/rustdesk) - 远程桌面软件，开箱即用，无需任何配置。您完全掌控数据，不用担心安全问题。
- [Ubuntu Desktop Installer](https://github.com/canonical/ubuntu-desktop-installer) - This project is a modern implementation of the Ubuntu Desktop installer.
- [UniControlHub](https://github.com/rohitsangwan01/uni_control_hub) - Seamlessly bridge your Desktop and Mobile devices

## API

<!-- README_DOC_GEN -->
### WindowManager

#### Methods

##### waitUntilReadyToShow

Wait until ready to show.

##### destroy

Force closing the window.

##### close

Try to close the window.

##### isPreventClose

Check if is intercepting the native close signal.

##### setPreventClose

Set if intercept the native close signal. May useful when combine with the onclose event listener.
This will also prevent the manually triggered close event.

##### focus

Focuses on the window.

##### blur  `macos`  `windows`

Removes focus from the window.


##### isFocused  `macos`  `windows`

Returns `bool` - Whether window is focused.


##### show

Shows and gives focus to the window.

##### hide

Hides the window.

##### isVisible

Returns `bool` - Whether the window is visible to the user.

##### isMaximized

Returns `bool` - Whether the window is maximized.

##### maximize

Maximizes the window. `vertically` simulates aero snap, only works on Windows

##### unmaximize

Unmaximizes the window.

##### isMinimized

Returns `bool` - Whether the window is minimized.

##### minimize

Minimizes the window. On some platforms the minimized window will be shown in the Dock.

##### restore

Restores the window from minimized state to its previous state.

##### isFullScreen

Returns `bool` - Whether the window is in fullscreen mode.

##### setFullScreen

Sets whether the window should be in fullscreen mode.

##### isDockable  `windows`

Returns `bool` - Whether the window is dockable or not.


##### isDocked  `windows`

Returns `bool` - Whether the window is docked.


##### dock  `windows`

Docks the window. only works on Windows


##### undock  `windows`

Undocks the window. only works on Windows


##### setAspectRatio

This will make a window maintain an aspect ratio.

##### setBackgroundColor

Sets the background color of the window.

##### setAlignment

Move the window to a position aligned with the screen.

##### center

Moves window to the center of the screen.

##### getBounds

Returns `Rect` - The bounds of the window as Object.

##### setBounds

Resizes and moves the window to the supplied bounds.

##### getSize

Returns `Size` - Contains the window's width and height.

##### setSize

Resizes the window to `width` and `height`.

##### getPosition

Returns `Offset` - Contains the window's current position.

##### setPosition

Moves window to position.

##### setMinimumSize

Sets the minimum size of window to `width` and `height`.

##### setMaximumSize

Sets the maximum size of window to `width` and `height`.

##### isResizable

Returns `bool` - Whether the window can be manually resized by the user.

##### setResizable

Sets whether the window can be manually resized by the user.

##### isMovable  `macos`

Returns `bool` - Whether the window can be moved by user.


##### setMovable  `macos`

Sets whether the window can be moved by user.


##### isMinimizable  `macos`  `windows`

Returns `bool` - Whether the window can be manually minimized by the user.


##### setMinimizable  `macos`  `windows`

Sets whether the window can be manually minimized by user.


##### isClosable  `windows`

Returns `bool` - Whether the window can be manually closed by user.


##### isMaximizable  `macos`  `windows`

Returns `bool` - Whether the window can be manually maximized by the user.


##### setMaximizable

Sets whether the window can be manually maximized by the user.

##### setClosable  `macos`  `windows`

Sets whether the window can be manually closed by user.


##### isAlwaysOnTop

Returns `bool` - Whether the window is always on top of other windows.

##### setAlwaysOnTop

Sets whether the window should show always on top of other windows.

##### isAlwaysOnBottom

Returns `bool` - Whether the window is always below other windows.

##### setAlwaysOnBottom  `linux`  `windows`

Sets whether the window should show always below other windows.


##### getTitle

Returns `String` - The title of the native window.

##### setTitle

Changes the title of native window to title.

##### setTitleBarStyle

Changes the title bar style of native window.

##### getTitleBarHeight

Returns `int` - The title bar height of the native window.

##### isSkipTaskbar

Returns `bool` - Whether skipping taskbar is enabled.

##### setSkipTaskbar

Makes the window not show in the taskbar / dock.

##### setProgressBar  `macos`  `windows`

Sets progress value in progress bar. Valid range is [0, 1.0].


##### setIcon  `windows`

Sets window/taskbar icon.


##### isVisibleOnAllWorkspaces  `macos`

Returns `bool` - Whether the window is visible on all workspaces.


##### setVisibleOnAllWorkspaces  `macos`

Sets whether the window should be visible on all workspaces.

Note: If you need to support dragging a window on top of a fullscreen
window on another screen, you need to modify MainFlutterWindow
to inherit from NSPanel

```swift
class MainFlutterWindow: NSPanel {
// ...
}
```


##### setBadgeLabel  `macos`

Set/unset label on taskbar(dock) app icon

Note that it's required to request access at your AppDelegate.swift like this:
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])


##### hasShadow  `macos`  `windows`

Returns `bool` - Whether the window has a shadow. On Windows, always returns true unless window is frameless.


##### setHasShadow  `macos`  `windows`

Sets whether the window should have a shadow. On Windows, doesn't do anything unless window is frameless.


##### getOpacity

Returns `double` - between 0.0 (fully transparent) and 1.0 (fully opaque).

##### setOpacity

Sets the opacity of the window.

##### setBrightness

Sets the brightness of the window.

##### setIgnoreMouseEvents

Makes the window ignore all mouse events.

All mouse events happened in this window will be passed to the window below this window, but if this window has focus, it will still receive keyboard events.

##### startDragging

Starts a window drag based on the specified mouse-down event.

##### startResizing  `linux`  `windows`

Starts a window resize based on the specified mouse-down & mouse-move event.


##### grabKeyboard  `linux`

Grabs the keyboard.

##### ungrabKeyboard  `linux`

Ungrabs the keyboard.

### WindowListener

#### Methods

##### onWindowClose

Emitted when the window is going to be closed.

##### onWindowFocus

Emitted when the window gains focus.

##### onWindowBlur

Emitted when the window loses focus.

##### onWindowMaximize

Emitted when window is maximized.

##### onWindowUnmaximize

Emitted when the window exits from a maximized state.

##### onWindowMinimize

Emitted when the window is minimized.

##### onWindowRestore

Emitted when the window is restored from a minimized state.

##### onWindowResize

Emitted after the window has been resized.

##### onWindowResized  `macos`  `windows`

Emitted once when the window has finished being resized.


##### onWindowMove

Emitted when the window is being moved to a new position.

##### onWindowMoved  `macos`  `windows`

Emitted once when the window is moved to a new position.


##### onWindowEnterFullScreen

Emitted when the window enters a full-screen state.

##### onWindowLeaveFullScreen

Emitted when the window leaves a full-screen state.

##### onWindowDocked  `windows`

Emitted when the window entered a docked state.


##### onWindowUndocked  `windows`

Emitted when the window leaves a docked state.


##### onWindowEvent

Emitted all events.


<!-- README_DOC_GEN -->

## 贡献者

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lijy91"><img src="https://avatars.githubusercontent.com/u/3889523?v=4?s=100" width="100px;" alt="LiJianying"/><br /><sub><b>LiJianying</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=lijy91" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/damywise"><img src="https://avatars.githubusercontent.com/u/25608913?v=4?s=100" width="100px;" alt=" A Arif A S"/><br /><sub><b> A Arif A S</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=damywise" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jpnurmi"><img src="https://avatars.githubusercontent.com/u/140617?v=4?s=100" width="100px;" alt="J-P Nurmi"/><br /><sub><b>J-P Nurmi</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=jpnurmi" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Dixeran"><img src="https://avatars.githubusercontent.com/u/22679810?v=4?s=100" width="100px;" alt="Dixeran"/><br /><sub><b>Dixeran</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=Dixeran" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nikitatg"><img src="https://avatars.githubusercontent.com/u/96043303?v=4?s=100" width="100px;" alt="nikitatg"/><br /><sub><b>nikitatg</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=nikitatg" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://merritt.codes/"><img src="https://avatars.githubusercontent.com/u/9575627?v=4?s=100" width="100px;" alt="Kristen McWilliam"/><br /><sub><b>Kristen McWilliam</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=Merrit" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Kingtous"><img src="https://avatars.githubusercontent.com/u/39793325?v=4?s=100" width="100px;" alt="Kingtous"/><br /><sub><b>Kingtous</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=Kingtous" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hlwhl"><img src="https://avatars.githubusercontent.com/u/7610615?v=4?s=100" width="100px;" alt="Prome"/><br /><sub><b>Prome</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=hlwhl" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://i.soit.tech/"><img src="https://avatars.githubusercontent.com/u/17426470?v=4?s=100" width="100px;" alt="Bin"/><br /><sub><b>Bin</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=boyan01" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/youxiachai"><img src="https://avatars.githubusercontent.com/u/929502?v=4?s=100" width="100px;" alt="youxiachai"/><br /><sub><b>youxiachai</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=youxiachai" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Allenxuxu"><img src="https://avatars.githubusercontent.com/u/20566897?v=4?s=100" width="100px;" alt="Allen Xu"/><br /><sub><b>Allen Xu</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=Allenxuxu" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://linwood.dev/"><img src="https://avatars.githubusercontent.com/u/20452814?v=4?s=100" width="100px;" alt="CodeDoctor"/><br /><sub><b>CodeDoctor</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=CodeDoctorDE" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jcbinet"><img src="https://avatars.githubusercontent.com/u/17210882?v=4?s=100" width="100px;" alt="Jean-Christophe Binet"/><br /><sub><b>Jean-Christophe Binet</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=jcbinet" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Jon-Salmon"><img src="https://avatars.githubusercontent.com/u/26483285?v=4?s=100" width="100px;" alt="Jon Salmon"/><br /><sub><b>Jon Salmon</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=Jon-Salmon" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/koral--"><img src="https://avatars.githubusercontent.com/u/3340954?v=4?s=100" width="100px;" alt="Karol Wrótniak"/><br /><sub><b>Karol Wrótniak</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=koral--" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/laiiihz"><img src="https://avatars.githubusercontent.com/u/35956195?v=4?s=100" width="100px;" alt="LAIIIHZ"/><br /><sub><b>LAIIIHZ</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=laiiihz" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/mikhailkulesh"><img src="https://avatars.githubusercontent.com/u/30557348?v=4?s=100" width="100px;" alt="Mikhail Kulesh"/><br /><sub><b>Mikhail Kulesh</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=mkulesh" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/prateekmedia"><img src="https://avatars.githubusercontent.com/u/41370460?v=4?s=100" width="100px;" alt="Prateek Sunal"/><br /><sub><b>Prateek Sunal</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=prateekmedia" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://ricardoboss.de/"><img src="https://avatars.githubusercontent.com/u/6266356?v=4?s=100" width="100px;" alt="Ricardo Boss"/><br /><sub><b>Ricardo Boss</b></sub></a><br /><a href="https://github.com/leanflutter/window_manager/commits?author=ricardoboss" title="Code">💻</a></td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <td align="center" size="13px" colspan="7">
        <img src="https://raw.githubusercontent.com/all-contributors/all-contributors-cli/1b8533af435da9854653492b1327a23a4dbd0a10/assets/logo-small.svg">
          <a href="https://all-contributors.js.org/docs/en/bot/usage">Add your contributions</a>
        </img>
      </td>
    </tr>
  </tfoot>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

## 许可证

[MIT](./LICENSE)
