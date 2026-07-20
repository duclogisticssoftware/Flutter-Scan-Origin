import 'package:flutter/foundation.dart';
import 'package:qrscan_app/models/app_notification.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';
import 'package:qrscan_app/services/notification_api_service.dart';

/// State unread badge + danh sách thông báo (Provider).
class NotificationInboxController extends ChangeNotifier {
  int unreadCount = 0;
  List<AppNotification> items = const [];
  bool loading = false;
  String? error;
  bool mobileSessionReady = false;

  Future<void> refresh({bool unreadOnly = false}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      mobileSessionReady = await MobileAuthService.isAuthenticated();
      if (!mobileSessionReady) {
        unreadCount = 0;
        items = const [];
        error = 'Chưa đăng nhập phiên duyệt phiếu (NVOAMASIS).';
        return;
      }

      final result = await NotificationApiService.list(
        unreadOnly: unreadOnly,
        take: 50,
      );
      unreadCount = result.unreadCount;
      items = result.items;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await NotificationApiService.markRead(id);
    final index = items.indexWhere((e) => e.id == id);
    if (index >= 0 && !items[index].isRead) {
      final updated = List<AppNotification>.from(items);
      updated[index] = AppNotification(
        id: items[index].id,
        senderUserId: items[index].senderUserId,
        receiverUserId: items[index].receiverUserId,
        message: items[index].message,
        createdAt: items[index].createdAt,
        isRead: true,
        isPhieuApprove: items[index].isPhieuApprove,
        phieuLoai: items[index].phieuLoai,
        phieuToken: items[index].phieuToken,
      );
      items = updated;
      if (unreadCount > 0) unreadCount -= 1;
      notifyListeners();
    } else {
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    await NotificationApiService.markAllRead();
    await refresh();
  }
}
