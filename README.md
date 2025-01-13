# cloudplayplus

CloudPlayPlus is a remote desktop software designed to provide users with a seamless and smooth experience for playing remote games. Currently, it achieves 2K resolution at 60 FPS with a latency of just 40ms (from company to home) using a customized version of libWebRTC for online game streaming.

However, there are still many exciting features under development, including H.265 hardware encoding and support for various hardware decoding solutions. CloudPlayPlus aims to continuously enhance performance and user experience in remote gaming.

## Getting Started
You can build and it as a simple flutter project. Run this project on Windows or MacOS as host, and you will be able to control the host on another clint, or https://www.cloudplayplus.com/ .

# Linux
Personally I use steam deck to develop this project. Here is the list of commands to make flutter runnable on steam deck:
steamdeck flutter:
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo steamos-readonly disable 
sudo pacman-key --populate holo 
sudo pacman -S base-devel cmake ninja glibc linux-api-headers gtk3 pango glib2 sysprof harfbuzz freetype2 libpng util-linux fribidi cairo lzo pixman gdk-pixbuf2 libcloudproviders atk at-spi2-atk dbus at-spi2-core libx11 xorgproto

To login to github desktop:
sudo pacman -S kwalletmanager
sudo pacman -S kwallet

sudo pacman -S tpm2-tss for secure_storage.

chrome debug:
set chrome path to 
var/lib/flatpak/app/com.google.Chrome/current/active/export/bin/com.google.Chrome
if using flatpak

# MacOS debug WebRTCFramework:
copy the framework and dysm to flutter-webrtc/macos
use xcode to build

first time:
modify pod
pod install in cloudplayplus/macos

# Web Debug
## use local server:
flutter run -d chrome --web-browser-flag "--disable-web-security"

rtc build:
python3 run.py build macos_arm64
