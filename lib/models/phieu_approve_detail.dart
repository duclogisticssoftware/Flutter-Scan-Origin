import 'package:qrscan_app/utils/vn_datetime.dart';

class PhieuApproveDetail {
  final String loai;
  final String? phieuId;
  final String token;
  final String? soPhieu;
  final String detailHtml;
  final bool? approve;
  final String? approveBy;
  final DateTime? approveDate;
  final String? remarks;
  final bool alreadyDecided;
  final bool canDecide;

  const PhieuApproveDetail({
    required this.loai,
    required this.token,
    required this.detailHtml,
    required this.alreadyDecided,
    required this.canDecide,
    this.phieuId,
    this.soPhieu,
    this.approve,
    this.approveBy,
    this.approveDate,
    this.remarks,
  });

  factory PhieuApproveDetail.fromJson(Map<String, dynamic> json) {
    final approveRaw = _pick(json, ['approve', 'Approve']);
    return PhieuApproveDetail(
      loai: (_pick(json, ['loai', 'Loai'])?.toString() ?? 'Thu'),
      phieuId: _pick(json, ['phieuId', 'PhieuId'])?.toString(),
      token: _pick(json, ['token', 'Token'])?.toString() ?? '',
      soPhieu: _pick(json, ['soPhieu', 'SoPhieu'])?.toString(),
      detailHtml: _pick(json, ['detailHtml', 'DetailHtml'])?.toString() ?? '',
      approve: approveRaw == null ? null : _asBool(approveRaw),
      approveBy: _pick(json, ['approveBy', 'ApproveBy'])?.toString(),
      approveDate: VnDateTime.parseApi(
        _pick(json, ['approveDate', 'ApproveDate'])?.toString(),
      ),
      remarks: _pick(json, ['remarks', 'Remarks'])?.toString(),
      alreadyDecided: _asBool(
        _pick(json, ['alreadyDecided', 'AlreadyDecided']),
      ),
      canDecide: _asBool(_pick(json, ['canDecide', 'CanDecide'])),
    );
  }

  String get loaiLabel => loai == 'Chi' ? 'Phiếu chi' : 'Phiếu thu';

  String get statusLabel {
    if (!alreadyDecided) return 'Chờ duyệt';
    if (approve == true) return 'Đã Approve';
    if (approve == false) return 'Đã Deny';
    return 'Đã quyết định';
  }

  bool get showActionButtons => canDecide && !alreadyDecided;

  static dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) return json[key];
    }
    // fallback: so khớp không phân biệt hoa thường
    final lowerMap = {
      for (final e in json.entries) e.key.toLowerCase(): e.value,
    };
    for (final key in keys) {
      final v = lowerMap[key.toLowerCase()];
      if (v != null) return v;
    }
    return null;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }
}

class PhieuDecideResult {
  final bool flag;
  final String message;

  const PhieuDecideResult({required this.flag, required this.message});

  factory PhieuDecideResult.fromJson(Map<String, dynamic> json) {
    final flagRaw = json['flag'] ?? json['Flag'];
    final messageRaw = json['message'] ?? json['Message'];
    return PhieuDecideResult(
      flag: PhieuApproveDetail._asBool(flagRaw),
      message: messageRaw?.toString() ?? '',
    );
  }
}
