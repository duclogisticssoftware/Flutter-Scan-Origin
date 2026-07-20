import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:qrscan_app/services/background_notification_service.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';

/// Poll nhanh khi app đang mở / resume → hiện local notification trên máy.
/// Bổ sung cho FCM (khi chưa có Firebase hoặc server chưa gửi push).
class NotificationPollService {
  NotificationPollService._();
  static final NotificationPollService instance = NotificationPollService._();

  Timer? _timer;
  bool _running = false;

  /// Mỗi 45s khi session mobile còn — đủ để thấy noti gần như realtime khi app mở.
  Future<void> start({Duration interval = const Duration(seconds: 45)}) async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final token = await MobileAuthService.getAccessToken();
    if (token == null || token.isEmpty) return;

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
    await _tick();
    debugPrint('[NotifPoll] started interval=${interval.inSeconds}s');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('[NotifPoll] stopped');
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      final token = await MobileAuthService.getAccessToken();
      if (token == null || token.isEmpty) {
        stop();
        return;
      }
      await BackgroundNotificationService.syncOnce();
    } catch (e) {
      debugPrint('[NotifPoll] tick error: $e');
    } finally {
      _running = false;
    }
  }
}
