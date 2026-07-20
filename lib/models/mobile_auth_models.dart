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
    String? str(dynamic v) => v?.toString();
    bool asBool(dynamic v) {
      if (v == true || v == 1) return true;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1';
      }
      return false;
    }

    final flagRaw = json['flag'] ?? json['Flag'];
    final message = str(json['message'] ?? json['Message']) ?? '';
    final accessToken = str(json['accessToken'] ?? json['AccessToken']);
    final expiresRaw = json['expiresAtUtc'] ?? json['ExpiresAtUtc'];

    return MobileLoginResult(
      flag: asBool(flagRaw),
      message: message,
      accessToken: accessToken,
      expiresAtUtc: expiresRaw != null
          ? DateTime.tryParse(expiresRaw.toString())
          : null,
      tenantId: str(json['tenantId'] ?? json['TenantId']),
      databaseName: str(json['databaseName'] ?? json['DatabaseName']),
      usrId: str(json['usrId'] ?? json['UsrId']),
      usr: str(json['usr'] ?? json['Usr']),
      name: str(json['name'] ?? json['Name']),
      email: str(json['email'] ?? json['Email']),
      department: str(json['department'] ?? json['Department']),
    );
  }
}
