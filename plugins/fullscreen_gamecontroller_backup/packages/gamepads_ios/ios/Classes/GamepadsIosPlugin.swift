import Flutter
import GameController
import UIKit

public class GamepadsIosPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    let gamepads = GamepadsListener()

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()

        self.gamepads.listener = onGamepadEvent
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "xyz.luan/gamepads", binaryMessenger: registrar.messenger())
        let instance = GamepadsIosPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listGamepads":
            result(listGamepads())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func onGamepadEvent(gamepadId: Int, gamepad: GCExtendedGamepad, element: GCControllerElement) {
        for (key, value) in getValues(element: element) {
            let arguments: [String: Any] = [
                "gamepadId": String(gamepadId),
                "time": Int(getTimestamp(gamepad: gamepad)),
                "type": element.isAnalog ? "analog" : "button",
                "key": key,
                "value": value,
            ]
            channel.invokeMethod("onGamepadEvent", arguments: arguments)
        }
    }

    private func getValues(element: GCControllerElement) -> [(String, Float)] {
        let name = getNameForElement(element: element)
        if let element = element as? GCControllerButtonInput {
            return [(name ?? "Unknown button", element.value)]
        } else if let element = element as? GCControllerAxisInput {
            return [(name ?? "Unknown axis", element.value)]
        } else if let element = element as? GCControllerDirectionPad {
            return [
                (maybeConcat(name, "xAxis"), element.xAxis.value),
                (maybeConcat(name, "yAxis"), element.yAxis.value)
            ]
        } else {
            return []
        }
    }
    
    private func getNameForElement(element: GCControllerElement) -> String? {
        if #available(iOS 14.0, *) {
            return element.sfSymbolsName
        } else {
            return nil
        }
    }

    private func getTimestamp(gamepad: GCExtendedGamepad) -> TimeInterval {
        if #available(iOS 14.0, *) {
            return gamepad.lastEventTimestamp
        } else {
            return Date().timeIntervalSince1970
        }
    }

    private func getName(gamepad: GCExtendedGamepad) -> String {
        if #available(iOS 14.0, *) {
            let device = gamepad.device
            return maybeConcat(device?.vendorName, device?.productCategory) ?? "Unknown device"
        } else {
            return "Unknown device"
        }
    }

    private func listGamepads() -> [[String: Any?]] {
        return gamepads.gamepads.enumerated().map { (index, gamepad) in
            [ "id": String(index), "name": getName(gamepad: gamepad) ]
        }
    }

    private func maybeConcat(_ string1: String?, _ string2: String) -> String {
        return maybeConcat(string1, string2)!
    }

    private func maybeConcat(_ strings: String?...) -> String? {
        let nonNull = strings.compactMap { $0 }
        if (nonNull.isEmpty) {
            return nil
        }
        return nonNull.joined(separator: " - ")
    }
}

extension Optional {
    func map<T>(_ closure: (Wrapped) -> T) -> T? {
        if let value = self {
            return closure(value)
        } else {
            return nil
        }
    }
}
