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
    final message = (json['message'] as String?) ?? '';
    final parsed = _parsePhieuApproveMessage(message);

    final isPhieuApprove =
        json['isPhieuApprove'] == true || parsed != null;
    final phieuLoai =
        (json['phieuLoai'] as String?) ?? parsed?.loai;
    final phieuToken =
        (json['phieuToken'] as String?) ?? parsed?.token;

    return AppNotification(
      id: (json['id'] ?? '').toString(),
      senderUserId: json['senderUserId']?.toString(),
      receiverUserId: json['receiverUserId']?.toString(),
      message: message,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      isRead: json['isRead'] == true,
      isPhieuApprove: isPhieuApprove,
      phieuLoai: phieuLoai,
      phieuToken: phieuToken,
    );
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
