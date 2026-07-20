import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // FCM: firebase_messaging plugin tự đăng ký remote notifications.
    // Cần GoogleService-Info.plist trong ios/Runner khi bật Firebase.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
