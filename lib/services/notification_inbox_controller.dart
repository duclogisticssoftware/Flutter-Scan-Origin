import 'package:flutter/foundation.dart';
import 'package:qrscan_app/config/app_config.dart';
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
  String? mobileDatabaseName;
  String? statusHint;

  Future<void> refresh({bool unreadOnly = false}) async {
    loading = true;
    error = null;
    statusHint = null;
    notifyListeners();

    try {
      final token = await MobileAuthService.getAccessToken();
      mobileDatabaseName = await MobileAuthService.getDatabaseName();
      mobileSessionReady =
          token != null && token.isNotEmpty && await MobileAuthService.me();

      if (!mobileSessionReady) {
        unreadCount = 0;
        items = const [];
        error =
            'Chưa có phiên NVOAMASIS — không tải được thông báo duyệt phiếu.';
        statusHint =
            'Host: $mobileApiBase\n'
            'Hãy Logout → Login lại (cùng thông tin web). '
            'Nếu vẫn lỗi, kiểm tra databaseName / user có quyền duyệt trên web.';
        debugPrint('[Inbox] no mobile session. host=$mobileApiBase');
        return;
      }

      final result = await NotificationApiService.list(
        unreadOnly: unreadOnly,
        take: 50,
      );
      unreadCount = result.unreadCount;
      items = result.items;
      if (items.isEmpty) {
        statusHint =
            'Đã kết nối NVOAMASIS'
            '${mobileDatabaseName != null ? ' (DB: $mobileDatabaseName)' : ''}, '
            'nhưng chưa có message. Trên web tạo yêu cầu duyệt gửi đúng user này.';
      }
      debugPrint(
        '[Inbox] ok unread=$unreadCount items=${items.length} '
        'db=$mobileDatabaseName host=$mobileApiBase',
      );
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      statusHint = 'Host: $mobileApiBase';
      debugPrint('[Inbox] error: $error');
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
