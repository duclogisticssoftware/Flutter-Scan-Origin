import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/models/app_notification.dart';
import 'package:qrscan_app/services/mobile_http_service.dart';

class NotificationApiService {
  static Future<NotificationListResult> list({
    bool unreadOnly = false,
    int take = 50,
  }) async {
    final response = await MobileHttpService.get(
      '$mobileApiBase/api/mobile/notifications'
      '?unreadOnly=$unreadOnly&take=$take',
    );

    final data = MobileHttpService.tryDecode(response);
    if (!MobileHttpService.isSuccess(response) || data == null) {
      throw Exception(MobileHttpService.getErrorMessage(response));
    }
    return NotificationListResult.fromJson(data);
  }

  static Future<void> markRead(String id) async {
    final response = await MobileHttpService.post(
      '$mobileApiBase/api/mobile/notifications/$id/read',
    );
    if (!MobileHttpService.isSuccess(response)) {
      throw Exception(MobileHttpService.getErrorMessage(response));
    }
  }

  static Future<void> markAllRead() async {
    final response = await MobileHttpService.post(
      '$mobileApiBase/api/mobile/notifications/read-all',
    );
    if (!MobileHttpService.isSuccess(response)) {
      throw Exception(MobileHttpService.getErrorMessage(response));
    }
  }
}
