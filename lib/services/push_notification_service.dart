import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/navigation/app_navigator.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';
import 'package:qrscan_app/services/mobile_http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local notifications + đăng ký FCM token (khi Firebase sẵn sàng).
/// Background sync dùng [BackgroundNotificationService] khi chưa có FCM server push.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'phieu_approve_channel';
  static const _channelName = 'Duyệt phiếu thu/chi';
  static const _seenIdsKey = 'notif_seen_ids';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String phieuToken)? onPhieuApproveTap;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Thông báo yêu cầu duyệt phiếu thu/chi',
        importance: Importance.high,
      ),
    );

    await _requestPermission();
    _initialized = true;
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['type'] == 'PHIEU_APPROVE') {
        final token = data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          onPhieuApproveTap?.call(token);
          AppNavigator.openPhieuApprove(token);
        }
      }
    } catch (e) {
      debugPrint('[Push] parse local payload error: $e');
    }
  }

  Future<void> showPhieuApproveNotification({
    required String id,
    required String title,
    required String body,
    required String phieuToken,
    String? loai,
  }) async {
    if (!_initialized) await init();

    await _local.show(
      id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Thông báo yêu cầu duyệt phiếu thu/chi',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        'type': 'PHIEU_APPROVE',
        'token': phieuToken,
        'loai': loai,
      }),
    );
  }

  Future<Set<String>> getSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenIdsKey)?.toSet() ?? <String>{};
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_seenIdsKey)?.toSet() ?? <String>{};
    current.addAll(ids);
    // Giữ tối đa 200 id gần nhất
    final trimmed = current.toList().reversed.take(200).toList().reversed;
    await prefs.setStringList(_seenIdsKey, trimmed.toList());
  }

  Future<void> clearSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenIdsKey);
  }

  /// Đăng ký device token lên backend (FCM nếu có).
  Future<void> registerDeviceToken(String token) async {
    await MobileAuthService.saveFcmToken(token);
    final platform = Platform.isIOS ? 'ios' : 'android';
    final response = await MobileHttpService.post(
      '$mobileApiBase/api/mobile/device/push-token',
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (!MobileHttpService.isSuccess(response)) {
      debugPrint(
        '[Push] register token failed: ${MobileHttpService.getErrorMessage(response)}',
      );
    }
  }

  Future<void> unregisterDeviceToken() async {
    final token = await MobileAuthService.getFcmToken();
    if (token == null || token.isEmpty) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await MobileHttpService.delete(
        '$mobileApiBase/api/mobile/device/push-token',
        body: {'token': token, 'platform': platform},
      );
    } catch (e) {
      debugPrint('[Push] unregister token error: $e');
    } finally {
      await MobileAuthService.clearFcmToken();
    }
  }

}
