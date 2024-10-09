# gamepads

<p align="center">
  A Flutter plugin to handle gamepad input across multiple platforms. Froked from gamepads and add web implementation.
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/gamepads">
    <img
      src="https://img.shields.io/pub/v/gamepads.svg?style=popout&include_prereleases"
      alt="Badge for latest release"
    />
  </a>
  <a title="Build Status" href="https://github.com/flame-engine/gamepads/actions?query=workflow%3Acicd+branch%3Amain">
    <img
      src="https://github.com/flame-engine/gamepads/workflows/cicd/badge.svg?branch=main"
      alt="Badge for build status"
    />
  </a>
  <a title="Discord" href="https://discord.gg/pxrBmy4">
    <img src="https://img.shields.io/discord/509714518008528896.svg" alt="Badge for Discord server"/>
  </a>
  <a title="Melos" href="https://github.com/invertase/melos">
    <img
      src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg"
      alt="Badge showing that Melos is used"
    />
  </a>
</p>

---

> **Note**: This plugin is still in beta. All APIs are subject to change. Any feedback is appreciated.

Gamepads is a Flutter plugin to handle gamepad (or joystick) input across multiple platforms.

It supports multiple simultaneously connected gamepads, and will automatically detect and listen to
new connections.


## Getting Started

The `list` method will list all currently connected gamepads:

```dart
  final gamepads = await Gamepads.list();
  // ...
```

This uses the data class `GamepadController`, which has an `id` and a user-facing `name`.

And the `events` stream will broadcast input events from all gamepads:

```dart
  Gamepads.events.listen((event) {
    // ...
  });
```

You can also listen to events only for a specific gamepad with `eventsByGamepad`.

Events are described by the data class `GamepadEvent`:

```dart
class GamepadEvent {
  /// The id of the gamepad controller that fired the event.
  final String gamepadId;

  /// The timestamp in which the event was fired, in milliseconds since epoch.
  final int timestamp;

  /// The [KeyType] of the key that was triggered.
  final KeyType type;

  /// A platform-dependant identifier for the key that was triggered.
  final String key;

  /// The current value of the key.
  final double value;

  // ...
}
```


## Next Steps

As mentioned, this is still a WIP library. Not only APIs are expected to change if needed, but we
 plan to add more features, like:

- stream to listen for connecting/disconnecting gamepads
- get current state of a gamepad
- add support for web and even mobile

If you are interested in helping, please reach out!
You can use GitHub or our [Discord server](https://discord.gg/pxrBmy4).


## Android Integration

The Android implementation requires the application's Activity to forward input events (and
input devices) to the plugin. Below is an example of a MainActivity for a clean Flutter project
that has implemented the required boilerplate code. For many projects it will be possible to simply
duplicate this setup.

```dart
package [YOUR_PACKAGE_NAME]

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

class MainActivity: FlutterActivity(), GamepadsCompatibleActivity {
    var keyListener: ((KeyEvent) -> Boolean)? = null
    var motionListener: ((MotionEvent) -> Boolean)? = null

    override fun dispatchGenericMotionEvent(motionEvent: MotionEvent): Boolean {
        return motionListener?.invoke(motionEvent) ?: false
    }
    
    override fun dispatchKeyEvent(keyEvent: KeyEvent): Boolean {
        return keyListener?.invoke(keyEvent) ?: false
    }

    override fun registerInputDeviceListener(
      listener: InputManager.InputDeviceListener, handler: Handler?) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, null)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyListener = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionListener = handler
    }
}

```


## Support

The simplest way to show us your support is by giving the project a star! :star:

If you want, you can also support us monetarily by donating through OpenCollective:

<a href="https://opencollective.com/blue-fire/donate" target="_blank">
  <img
    src="https://opencollective.com/blue-fire/donate/button@2x.png?color=blue"
    width=200
    alt="Open Collective donate button"
  />
</a>

Through GitHub Sponsors:

<a href="https://github.com/sponsors/bluefireteam" target="_blank">
  <img
    src="https://img.shields.io/badge/Github%20Sponsor-blue?style=for-the-badge&logo=github&logoColor=white"
    width=200
    alt="GitHub Sponsor button"
  />
</a>

Or by becoming a patron on Patreon:

<a href="https://www.patreon.com/bluefireoss" target="_blank">
  <img
   src="https://c5.patreon.com/external/logo/become_a_patron_button.png"
   width=200
   alt="Patreon donate button"
  />
</a>
