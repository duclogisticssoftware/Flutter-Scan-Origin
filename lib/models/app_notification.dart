import 'package:qrscan_app/utils/vn_datetime.dart';

class AppNotification {
  final String id;
  final String? senderUserId;
  final String? receiverUserId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final bool isPhieuApprove;
  final String? phieuLoai;
  final String? phieuToken;

  const AppNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.isPhieuApprove,
    this.senderUserId,
    this.receiverUserId,
    this.phieuLoai,
    this.phieuToken,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final message =
        (json['message'] ?? json['Message'])?.toString() ?? '';
    final parsed = _parsePhieuApproveMessage(message);

    final isPhieuApprove = _asBool(
          json['isPhieuApprove'] ?? json['IsPhieuApprove'],
        ) ||
        parsed != null;
    final phieuLoai = (json['phieuLoai'] ?? json['PhieuLoai'])?.toString() ??
        parsed?.loai;
    final rawToken = json['phieuToken'] ?? json['PhieuToken'];
    final phieuToken = rawToken?.toString().trim().isNotEmpty == true
        ? rawToken.toString().trim()
        : parsed?.token;

    return AppNotification(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      senderUserId:
          (json['senderUserId'] ?? json['SenderUserId'])?.toString(),
      receiverUserId:
          (json['receiverUserId'] ?? json['ReceiverUserId'])?.toString(),
      message: message,
      createdAt: VnDateTime.parseApi(
            (json['createdAt'] ?? json['CreatedAt'])?.toString(),
          ) ??
          DateTime.now().toUtc(),
      isRead: _asBool(json['isRead'] ?? json['IsRead']),
      isPhieuApprove: isPhieuApprove,
      phieuLoai: phieuLoai,
      phieuToken: phieuToken,
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  String get displayTitle {
    if (isPhieuApprove) {
      final loai = phieuLoai == 'Chi' ? 'chi' : 'thu';
      return 'Yêu cầu duyệt phiếu $loai';
    }
    return 'Thông báo';
  }
}

class _PhieuApproveParsed {
  final String loai;
  final String token;
  const _PhieuApproveParsed(this.loai, this.token);
}

_PhieuApproveParsed? _parsePhieuApproveMessage(String message) {
  final match = RegExp(
    r'\[PHIEU_APPROVE\|(Thu|Chi)\|([^\]]+)\]',
    caseSensitive: false,
  ).firstMatch(message);
  if (match == null) return null;
  return _PhieuApproveParsed(match.group(1)!, match.group(2)!.trim());
}

class NotificationListResult {
  final int unreadCount;
  final List<AppNotification> items;

  const NotificationListResult({
    required this.unreadCount,
    required this.items,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AppNotification>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(AppNotification.fromJson(item));
        } else if (item is Map) {
          items.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return NotificationListResult(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }
}
