// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

//enum ChannelName {
//  static let battery = "samples.flutter.io/battery"
//  static let charging = "samples.flutter.io/charging"
//}

enum ChannelName {
  static let getStringMethodChannel = "method.channel.example/getString"
  static let voidMethodChannel = "method.channel.example/voidMethod"
  static let timerChannel = "method.channel.example/timer"
    static let eventChannel = "method.channel.example/eventChannel"
}

enum BatteryState {
  static let charging = "charging"
  static let discharging = "discharging"
}

enum MyFlutterErrorCode {
  static let unavailable = "UNAVAILABLE"
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    let voidChannel = FlutterMethodChannel(name: ChannelName.voidMethodChannel,
                                              binaryMessenger: controller.binaryMessenger)
        let getStringMethodChannel = FlutterMethodChannel(name: ChannelName.getStringMethodChannel , binaryMessenger: controller.binaryMessenger)
        
        let timerMethodChannel = FlutterMethodChannel(name: ChannelName.timerChannel , binaryMessenger: controller.binaryMessenger)
        
        let eventChannel = FlutterMethodChannel(name: ChannelName.eventChannel,
                                                  binaryMessenger: controller.binaryMessenger)
        
        getStringMethodChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      guard call.method == "getStringMethodChannel" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.getString(result: result)
    })

    let chargingChannel = FlutterEventChannel(name: ChannelName.charging,
                                              binaryMessenger: controller.binaryMessenger)
    chargingChannel.setStreamHandler(self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getString(result: FlutterResult) {
    
      let userName = device.userName
   
    result(String("This is string returned from \(userName)'s Device"))
  }

  public func onListen(withArguments arguments: Any?,
                       eventSink: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = eventSink
    UIDevice.current.isBatteryMonitoringEnabled = true
    sendBatteryStateEvent()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(AppDelegate.onBatteryStateDidChange),
      name: UIDevice.batteryStateDidChangeNotification,
      object: nil)
    return nil
  }

  @objc private func onBatteryStateDidChange(notification: NSNotification) {
    sendBatteryStateEvent()
  }

  private func sendBatteryStateEvent() {
    guard let eventSink = eventSink else {
      return
    }

    switch UIDevice.current.batteryState {
    case .full:
      eventSink(BatteryState.charging)
    case .charging:
      eventSink(BatteryState.charging)
    case .unplugged:
      eventSink(BatteryState.discharging)
    default:
      eventSink(FlutterError(code: MyFlutterErrorCode.unavailable,
                             message: "Charging status unavailable",
                             details: nil))
    }
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
