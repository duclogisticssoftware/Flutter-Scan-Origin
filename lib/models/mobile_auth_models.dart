class MobileLoginResult {
  final bool flag;
  final String message;
  final String? accessToken;
  final DateTime? expiresAtUtc;
  final String? tenantId;
  final String? databaseName;
  final String? usrId;
  final String? usr;
  final String? name;
  final String? email;
  final String? department;

  const MobileLoginResult({
    required this.flag,
    required this.message,
    this.accessToken,
    this.expiresAtUtc,
    this.tenantId,
    this.databaseName,
    this.usrId,
    this.usr,
    this.name,
    this.email,
    this.department,
  });

  factory MobileLoginResult.fromJson(Map<String, dynamic> json) {
    return MobileLoginResult(
      flag: json['flag'] == true,
      message: (json['message'] as String?) ?? '',
      accessToken: json['accessToken'] as String?,
      expiresAtUtc: json['expiresAtUtc'] != null
          ? DateTime.tryParse(json['expiresAtUtc'].toString())
          : null,
      tenantId: json['tenantId'] as String?,
      databaseName: json['databaseName'] as String?,
      usrId: json['usrId'] as String?,
      usr: json['usr'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      department: json['department'] as String?,
    );
  }
}
