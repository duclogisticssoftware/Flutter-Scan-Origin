/// Định dạng ngày giờ theo chuẩn Việt Nam (UTC+7).
class VnDateTime {
  VnDateTime._();

  static const Duration _vnOffset = Duration(hours: 7);

  /// Parse ISO từ API: thiếu timezone thì coi là UTC.
  static DateTime? parseApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final hasTz =
        s.endsWith('Z') ||
        s.endsWith('z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s);
    return DateTime.tryParse(hasTz ? s : '${s}Z');
  }

  /// Chuyển sang giờ Việt Nam (UTC+7), không phụ thuộc timezone máy.
  static DateTime toVietnam(DateTime value) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.add(_vnOffset);
  }

  /// `dd/MM/yyyy HH:mm`
  static String format(DateTime? value) {
    if (value == null) return '';
    final vn = toVietnam(value);
    return '${_pad(vn.day)}/${_pad(vn.month)}/${vn.year} '
        '${_pad(vn.hour)}:${_pad(vn.minute)}';
  }

  /// `dd/MM/yyyy HH:mm:ss`
  static String formatWithSeconds(DateTime? value) {
    if (value == null) return '';
    final vn = toVietnam(value);
    return '${_pad(vn.day)}/${_pad(vn.month)}/${vn.year} '
        '${_pad(vn.hour)}:${_pad(vn.minute)}:${_pad(vn.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
