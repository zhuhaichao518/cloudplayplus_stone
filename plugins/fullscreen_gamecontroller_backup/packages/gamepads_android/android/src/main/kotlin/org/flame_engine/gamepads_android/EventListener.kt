package org.flame_engine.gamepads_android

import android.util.Log
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

data class SupportedAxis(val axisId: Int, val invert: Boolean = false)

class EventListener {
    companion object {
        private const val TAG = "EventListener"
        private const val axisEpisilon = 0.001
    }
    private val lastAxisValue = mutableMapOf<Int, Float>()
    private val supportedAxes = listOf<SupportedAxis>(
        SupportedAxis(MotionEvent.AXIS_X),
        SupportedAxis(MotionEvent.AXIS_Y, invert = true),
        SupportedAxis(MotionEvent.AXIS_Z),
        SupportedAxis(MotionEvent.AXIS_RZ, invert = true),
        SupportedAxis(MotionEvent.AXIS_HAT_X),
        SupportedAxis(MotionEvent.AXIS_HAT_Y, invert = true),
        SupportedAxis(MotionEvent.AXIS_LTRIGGER),
        SupportedAxis(MotionEvent.AXIS_RTRIGGER),
    )

    fun onKeyEvent(keyEvent: KeyEvent, channel: MethodChannel): Boolean {
        val arguments = mapOf(
            "gamepadId" to keyEvent.getDeviceId().toString(),
            "time" to keyEvent.getEventTime(),
            "type" to "button",
            "key" to KeyEvent.keyCodeToString(keyEvent.getKeyCode()),
            "value" to keyEvent.getAction().toDouble()
        )
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }

    fun onMotionEvent(motionEvent: MotionEvent, channel: MethodChannel): Boolean {
        supportedAxes.forEach {
            reportAxis(motionEvent, channel, it.axisId, it.invert)
        }
        return true
    }

    private fun reportAxis(motionEvent: MotionEvent, channel: MethodChannel, axis: Int, invert: Boolean = false): Boolean {
        val multiplier = if (invert) -1 else 1
        val value = motionEvent.getAxisValue(axis) * multiplier

        // No-op if threshold is not met
        val lastValue = lastAxisValue[axis]
        if (lastValue is Float) {
            if (abs(value - lastValue) < axisEpisilon) {
                return true;
            }
        }
        // Update last value
        lastAxisValue[axis] = value

        val arguments = mapOf(
            "gamepadId" to motionEvent.getDeviceId().toString(),
            "time" to motionEvent.getEventTime(),
            "type" to "analog",
            "key" to MotionEvent.axisToString(axis),
            "value" to value,
        )
        channel.invokeMethod("onGamepadEvent", arguments)
        return true
    }
}