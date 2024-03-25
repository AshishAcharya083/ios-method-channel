import UIKit
import Flutter

enum ChannelName {
    static let getStringMethodChannel = "method.channel.example/getString"
    static let voidMethodChannel = "method.channel.example/voidMethod"
    static let charging = "samples.flutter.io/charging"
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
        
        // Setting up a method channel for returning a string from native code.
        let getStringMethodChannel = FlutterMethodChannel(name: ChannelName.getStringMethodChannel, binaryMessenger: controller.binaryMessenger)
        
        // Setting up a method channel for calling a void method in native code.
        let voidChannel = FlutterMethodChannel(name: ChannelName.voidMethodChannel, binaryMessenger: controller.binaryMessenger)
        
        // Handling calls from Flutter to the getStringMethodChannel.
        getStringMethodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            guard call.method == "getStringMethodChannel" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.getString(result: result)
        })
        
        // Handling calls from Flutter to the voidMethodChannel.
        voidChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            guard call.method == "voidMethodChannel" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.printNatively()
        })
        
        // Setting up an event channel for sending battery status updates to Flutter.
        let chargingChannel = FlutterEventChannel(name: ChannelName.charging, binaryMessenger: controller.binaryMessenger)
        chargingChannel.setStreamHandler(self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Method to return a string from native code.
    private func getString(result: FlutterResult) {
        let device = UIDevice.current
        let userName = device.systemName
        result("This is string returned from \(userName) Device")
    }
    
    // Method to print a message natively.
    private func printNatively() {
        print("\n**** Hi this is Native print ****\n")
    }
    
    // Setting up listener for battery status updates.
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
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
    
    // Handling battery state changes.
    @objc private func onBatteryStateDidChange(notification: NSNotification) {
        sendBatteryStateEvent()
    }
    
    // Sending the current battery state to Flutter.
    private func sendBatteryStateEvent() {
        guard let eventSink = eventSink else {
            return
        }
        
        switch UIDevice.current.batteryState {
        case .full, .charging:
            eventSink(BatteryState.charging)
        case .unplugged:
            eventSink(BatteryState.discharging)
        default:
            eventSink(FlutterError(code: MyFlutterErrorCode.unavailable,
                                   message: "Charging status unavailable",
                                   details: nil))
        }
    }
    
    // Handling cancellation of battery status updates.
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
}
