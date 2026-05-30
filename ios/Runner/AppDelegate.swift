import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    let settingsChannel = FlutterMethodChannel(name: "com.huflit.smart_canteen/settings",
                                              binaryMessenger: controller.binaryMessenger)
    settingsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "openSettings" {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    let badgeChannel = FlutterMethodChannel(name: "com.huflit.smart_canteen/badge",
                                            binaryMessenger: controller.binaryMessenger)
    badgeChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setBadge" {
        if let count = call.arguments as? Int {
          if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
              if let error = error {
                print("Error setting badge: \(error)")
              }
            }
          } else {
            UIApplication.shared.applicationIconBadgeNumber = count
          }
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
