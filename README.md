# cloudplayplus

CloudPlayPlus (https://www.cloudplayplus.com, currently only available in mainland China) is a remote desktop software designed to provide users with a seamless and smooth experience for playing remote games. Currently, it achieves 2K resolution at 60 FPS with a latency of just 40ms (from company to home) using a customized version of libWebRTC for online game streaming from my macbook to Windows machine (NVDIA RTX 3070Ti).

However, there are still many exciting features under development, including H.265 hardware encoding and support for various hardware decoding solutions(currently only NVDIA graphic card with encoding unit is supported). CloudPlayPlus aims to continuously enhance performance and user experience in remote gaming.

## Getting Started
You can build and run it as a simple flutter project (such as, flutter build windows). Before build you need to run flutter pub get in sub plugin folders to sync the whole project.

Run this project on Windows or MacOS as host, and you will be able to control the host on another client, or from https://www.cloudplayplus.com/web/. You need to register a account first.

# Some Additional Develop Material
# WebRTC
We use custom build of WebRTC for cloudplayplus. The main purpose is add hardware_acceleration support in WebRTC windows and some GPU texture support. We have added/modified some interfaces and you can check the difference from flutter-webrtc in this project and official [flutter-webrtc](https://github.com/flutter-webrtc/flutter-webrtc).

# Linux
Personally I use steam deck to develop this project. Here is the list of commands to make flutter runnable on steam deck:
steamdeck flutter:
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo steamos-readonly disable 
sudo pacman-key --populate holo 
sudo pacman -S base-devel cmake ninja glibc linux-api-headers gtk3 pango glib2 sysprof harfbuzz freetype2 libpng util-linux fribidi cairo lzo pixman gdk-pixbuf2 libcloudproviders atk at-spi2-atk dbus at-spi2-core libx11 xorgproto
```

To login to github desktop:
```bash
sudo pacman -S kwalletmanager
sudo pacman -S kwallet

sudo pacman -S tpm2-tss # for secure_storage.
```
chrome debug:
set chrome path to 
`var/lib/flatpak/app/com.google.Chrome/current/active/export/bin/com.google.Chrome`
if using flatpak

# MacOS debug WebRTCFramework:
copy the framework and dysm to flutter-webrtc/macos
use xcode to build

first time:
modify pod
`pod install` in cloudplayplus/macos

# Web Debug
## use local server:
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

rtc build:
```bash
python3 run.py build macos_arm64
```
