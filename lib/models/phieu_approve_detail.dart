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
    return PhieuApproveDetail(
      loai: (json['loai'] as String?) ?? 'Thu',
      phieuId: json['phieuId']?.toString(),
      token: (json['token'] as String?) ?? '',
      soPhieu: json['soPhieu'] as String?,
      detailHtml: (json['detailHtml'] as String?) ?? '',
      approve: json['approve'] is bool ? json['approve'] as bool : null,
      approveBy: json['approveBy'] as String?,
      approveDate: json['approveDate'] != null
          ? DateTime.tryParse(json['approveDate'].toString())
          : null,
      remarks: json['remarks'] as String?,
      alreadyDecided: json['alreadyDecided'] == true,
      canDecide: json['canDecide'] == true,
    );
  }

  String get loaiLabel => loai == 'Chi' ? 'Phiếu chi' : 'Phiếu thu';

  String get statusLabel {
    if (!alreadyDecided) return 'Chờ duyệt';
    if (approve == true) return 'Đã Approve';
    if (approve == false) return 'Đã Deny';
    return 'Đã quyết định';
  }
}

class PhieuDecideResult {
  final bool flag;
  final String message;

  const PhieuDecideResult({required this.flag, required this.message});

  factory PhieuDecideResult.fromJson(Map<String, dynamic> json) {
    return PhieuDecideResult(
      flag: json['flag'] == true,
      message: (json['message'] as String?) ?? '',
    );
  }
}
