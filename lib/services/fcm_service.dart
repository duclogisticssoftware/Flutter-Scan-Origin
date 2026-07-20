import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:qrscan_app/navigation/app_navigator.dart';
import 'package:qrscan_app/services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM BG] ${message.messageId} data=${message.data}');
}

/// FCM push — chỉ hoạt động khi đã cấu hình Firebase (google-services.json).
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool _ready = false;
  bool get isReady => _ready;

  Future<bool> init() async {
    if (kIsWeb) return false;
    if (!(Platform.isAndroid || Platform.isIOS)) return false;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleData(initial.data, openPage: true);
      }

      _ready = true;
      return true;
    } catch (e) {
      debugPrint('[FCM] Chưa cấu hình Firebase, dùng background poll: $e');
      _ready = false;
      return false;
    }
  }

  Future<String?> registerToken() async {
    if (!_ready) {
      final ok = await init();
      if (!ok) return null;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await PushNotificationService.instance.registerDeviceToken(token);
        FirebaseMessaging.instance.onTokenRefresh.listen((t) {
          PushNotificationService.instance.registerDeviceToken(t);
        });
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  void _onForeground(RemoteMessage message) {
    _handleData(message.data, openPage: false, showLocal: true, message: message);
  }

  void _onOpened(RemoteMessage message) {
    _handleData(message.data, openPage: true);
  }

  void _handleData(
    Map<String, dynamic> data, {
    required bool openPage,
    bool showLocal = false,
    RemoteMessage? message,
  }) {
    final type = data['type']?.toString();
    if (type != 'PHIEU_APPROVE') return;

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return;

    if (showLocal) {
      PushNotificationService.instance.showPhieuApproveNotification(
        id: message?.messageId ?? token,
        title: data['title']?.toString() ??
            message?.notification?.title ??
            'Yêu cầu duyệt phiếu',
        body: data['body']?.toString() ??
            message?.notification?.body ??
            '',
        phieuToken: token,
        loai: data['loai']?.toString(),
      );
    }

    if (openPage) {
      AppNavigator.openPhieuApprove(token);
    }
  }
}
