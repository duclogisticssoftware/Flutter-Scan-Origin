import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qrscan_app/firebase_options.dart';
import 'package:qrscan_app/navigation/app_navigator.dart';
import 'package:qrscan_app/services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('[FCM BG] init error: $e');
  }

  debugPrint('[FCM BG] ${message.messageId} data=${message.data}');

  // Hiện local notification khi app ở nền / bị kill (data-only hoặc kèm notification).
  try {
    final data = message.data;
    final type = data['type']?.toString();
    if (type != 'PHIEU_APPROVE') return;

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    const channel = AndroidNotificationChannel(
      PushNotificationService.channelId,
      PushNotificationService.channelName,
      description: 'Thông báo yêu cầu duyệt phiếu thu/chi',
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final title = data['title']?.toString() ??
        message.notification?.title ??
        'Yêu cầu duyệt phiếu';
    final body =
        data['body']?.toString() ?? message.notification?.body ?? '';

    await plugin.show(
      token.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload:
          '{"type":"PHIEU_APPROVE","token":"$token","loai":"${data['loai'] ?? ''}"}',
    );
  } catch (e) {
    debugPrint('[FCM BG] show local error: $e');
  }
}

/// FCM push — cần google-services.json + DefaultFirebaseOptions hợp lệ.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool _ready = false;
  bool _tokenRefreshBound = false;
  bool get isReady => _ready;

  Future<bool> init() async {
    if (kIsWeb) return false;
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    if (_ready) return true;

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '[FCM] Chưa cấu hình Firebase (google-services.json / firebase_options). '
        'Dùng poll + local notification.',
      );
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Android 13+ permission cũng xin qua local notifications / permission_handler
      await PushNotificationService.instance.init();

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        // Delay nhẹ để navigator sẵn sàng
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          _handleData(initial.data, openPage: true);
        });
      }

      _ready = true;
      debugPrint('[FCM] ready');
      return true;
    } catch (e) {
      debugPrint('[FCM] init failed, fallback poll: $e');
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
        debugPrint('[FCM] device token len=${token.length}');
        await PushNotificationService.instance.registerDeviceToken(token);
        if (!_tokenRefreshBound) {
          _tokenRefreshBound = true;
          FirebaseMessaging.instance.onTokenRefresh.listen((t) {
            PushNotificationService.instance.registerDeviceToken(t);
          });
        }
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  void _onForeground(RemoteMessage message) {
    _handleData(
      message.data,
      openPage: false,
      showLocal: true,
      message: message,
    );
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
    // Một số payload chỉ có notification + token trong data
    final token = data['token']?.toString();
    final isPhieu = type == 'PHIEU_APPROVE' ||
        (token != null && token.isNotEmpty && (data['loai'] != null));

    if (!isPhieu || token == null || token.isEmpty) return;

    if (showLocal) {
      PushNotificationService.instance.showPhieuApproveNotification(
        id: message?.messageId ?? token,
        title: data['title']?.toString() ??
            message?.notification?.title ??
            'Yêu cầu duyệt phiếu',
        body: data['body']?.toString() ?? message?.notification?.body ?? '',
        phieuToken: token,
        loai: data['loai']?.toString(),
      );
    }

    if (openPage) {
      AppNavigator.openPhieuApprove(token);
    }
  }
}
