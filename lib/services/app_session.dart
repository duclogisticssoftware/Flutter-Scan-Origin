import 'package:flutter/foundation.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/services/background_notification_service.dart';
import 'package:qrscan_app/services/fcm_service.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';
import 'package:qrscan_app/services/push_notification_service.dart';

class AppSession {
  /// Login NVOAMASIS + bật nhận thông báo nền (giữ session đến khi logout).
  static Future<String?> connectMobileAndNotifications({
    required String databaseName,
    required String sqlUserId,
    required String sqlPassword,
    required String appUserName,
    required String appPassword,
  }) async {
    try {
      await MobileAuthService.login(
        databaseName: databaseName,
        sqlUserId: sqlUserId,
        sqlPassword: sqlPassword,
        appUserName: appUserName,
        appPassword: appPassword,
      );
      await _startNotifications();
      return null;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[AppSession] mobile login failed: $msg');
      return msg;
    }
  }

  /// Khôi phục poll/FCM khi mở lại app mà chưa logout.
  static Future<void> restoreNotificationsIfLoggedIn() async {
    final token = await MobileAuthService.getAccessToken();
    if (token == null || token.isEmpty) return;
    await _startNotifications();
  }

  static Future<void> _startNotifications() async {
    await PushNotificationService.instance.init();
    await FcmService.instance.init();
    await FcmService.instance.registerToken();
    await BackgroundNotificationService.start();
  }

  static Future<void> logout() async {
    try {
      await PushNotificationService.instance.unregisterDeviceToken();
    } catch (_) {}
    try {
      await BackgroundNotificationService.stop();
    } catch (_) {}
    try {
      await PushNotificationService.instance.clearSeen();
    } catch (_) {}
    await MobileAuthService.clearSession();
    await AuthService.logout();
  }
}
