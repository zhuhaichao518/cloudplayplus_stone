package com.cloudplayplus.cloudplayplus

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

class MainActivity: FlutterActivity(), GamepadsCompatibleActivity {
    // Add gamepad implementation
    var keyListener: ((KeyEvent) -> Boolean)? = null
    var motionListener: ((MotionEvent) -> Boolean)? = null
    var lockedkeyListener: ((KeyEvent) -> Boolean)? = null

    override fun dispatchGenericMotionEvent(motionEvent: MotionEvent): Boolean {
        return motionListener?.invoke(motionEvent) ?: super.dispatchGenericMotionEvent(motionEvent)
    }

    /* Does not work for KEYCODE_VOLUME_DOWN on Android TV.
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                //eventSink?.success(true)
                return true
            }
            KeyEvent.KEYCODE_VOLUME_UP -> {
                //eventSink?.success(false)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }*/

    override fun dispatchKeyEvent(keyEvent: KeyEvent): Boolean {
        //return keyListener?.invoke(keyEvent) ?: super.dispatchKeyEvent(keyEvent)
        if (keyListener?.invoke(keyEvent) == true) {
            return true;
        }
        if (lockedkeyListener?.invoke(keyEvent) == true) {
            return true;
        }
        return super.dispatchKeyEvent(keyEvent);
    }

    override fun registerInputDeviceListener(
        listener: InputManager.InputDeviceListener, 
        handler: Handler?
    ) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, null)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyListener = handler
    }

    override fun registerLockedKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        lockedkeyListener = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionListener = handler
    }
}

