import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';
import 'package:qrscan_app/services/notification_api_service.dart';
import 'package:qrscan_app/services/push_notification_service.dart';
import 'package:workmanager/workmanager.dart';

const String kNotificationSyncTask = 'notification_sync_task';

/// Đồng bộ thông báo khi app ở nền (chưa logout).
/// Poll API mỗi ~15 phút; hiện local notification cho phiếu chưa đọc mới.
@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == kNotificationSyncTask ||
          task == Workmanager.iOSBackgroundTask) {
        await BackgroundNotificationService.syncOnce();
      }
      return true;
    } catch (e, st) {
      debugPrint('[BG Notif] error: $e\n$st');
      return false;
    }
  });
}

class BackgroundNotificationService {
  static Future<void> init() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    await Workmanager().initialize(
      notificationBackgroundDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Bật poll nền sau khi login mobile thành công (giữ session nếu chưa logout).
  static Future<void> start() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    await Workmanager().registerPeriodicTask(
      kNotificationSyncTask,
      kNotificationSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    // Chạy một lần ngay khi vào app (foreground)
    await syncOnce();
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    await Workmanager().cancelByUniqueName(kNotificationSyncTask);
  }

  static Future<void> syncOnce() async {
    final token = await MobileAuthService.getAccessToken();
    if (token == null || token.isEmpty) return;

    final result = await NotificationApiService.list(
      unreadOnly: true,
      take: 30,
    );

    final push = PushNotificationService.instance;
    await push.init();
    final seen = await push.getSeenIds();
    final newIds = <String>[];

    for (final item in result.items) {
      if (seen.contains(item.id)) continue;
      if (!item.isPhieuApprove || item.phieuToken == null) {
        newIds.add(item.id);
        continue;
      }

      await push.showPhieuApproveNotification(
        id: item.id,
        title: item.displayTitle,
        body: item.message,
        phieuToken: item.phieuToken!,
        loai: item.phieuLoai,
      );
      newIds.add(item.id);
    }

    if (newIds.isNotEmpty) {
      await push.markSeen(newIds);
    }
  }
}
