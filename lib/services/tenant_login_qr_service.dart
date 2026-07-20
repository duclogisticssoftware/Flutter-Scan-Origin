import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';

/// 5 field đăng nhập tenant (cùng hình web / NVOAMASIS QR).
class TenantLoginCredentials {
  final String databaseName;
  final String sqlUserId;
  final String sqlPassword;
  final String appUserName;
  final String appPassword;

  const TenantLoginCredentials({
    required this.databaseName,
    required this.sqlUserId,
    required this.sqlPassword,
    required this.appUserName,
    required this.appPassword,
  });

  bool get isComplete =>
      databaseName.isNotEmpty &&
      sqlUserId.isNotEmpty &&
      sqlPassword.isNotEmpty &&
      appUserName.isNotEmpty &&
      appPassword.isNotEmpty;
}

/// Resolve QR đăng nhập (token / JSON v2 / LoginUrl) → 5 thuộc tính form.
class TenantLoginQrService {
  /// Quét QR → lấy credentials để điền form (giống web `applyQueryPrefill`).
  static Future<TenantLoginCredentials> resolve(String qrInput) async {
    final trimmed = qrInput.trim();
    if (trimmed.isEmpty) {
      throw Exception('QR trống.');
    }

    // 1) LoginUrl kiểu web: .../Account/Login?db=&sqlUser=&sqlPass=&appUser=&appPass=
    final fromUrl = _tryParseLoginUrl(trimmed);
    if (fromUrl != null) return fromUrl;

    // 2) JSON QR cũ có sẵn 5 field
    final fromEmbeddedJson = _tryParseEmbeddedCredentials(trimmed);
    if (fromEmbeddedJson != null) return fromEmbeddedJson;

    // 3) Token thuần hoặc JSON v2 { version, token, tokenUrl } → GET NVOAMASIS
    final (token, tokenUrl) = _parseTokenInput(trimmed);
    if (token.isEmpty) {
      throw Exception('Không đọc được token từ QR.');
    }

    final requestUrl = (tokenUrl != null && tokenUrl.isNotEmpty)
        ? tokenUrl
        : '$mobileApiBase/api/tenant-login-qr/$token';

    debugPrint('[TenantQr] GET $requestUrl');
    final response = await http
        .get(
          Uri.parse(requestUrl),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'LMS-Mobile/1.0',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      throw Exception(
        'Mã QR đã hết hiệu lực hoặc đã được tạo lại. '
        'Vui lòng quét mã QR mới trên máy tính.',
      );
    }
    if (response.statusCode == 400) {
      throw Exception('Token QR không hợp lệ.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Không lấy được thông tin đăng nhập từ QR (HTTP ${response.statusCode}).',
      );
    }

    final data = _tryDecode(response.body);
    if (data == null) {
      throw Exception('Phản hồi QR không phải JSON hợp lệ.');
    }

    final creds = _fromPayloadMap(data);
    if (!creds.isComplete) {
      throw Exception('QR thiếu đủ 5 thuộc tính đăng nhập.');
    }
    return creds;
  }

  static TenantLoginCredentials? _tryParseLoginUrl(String input) {
    Uri? uri;
    try {
      uri = Uri.parse(input);
    } catch (_) {
      return null;
    }
    if (!uri.hasScheme || uri.queryParameters.isEmpty) return null;

    final db = uri.queryParameters['db']?.trim() ?? '';
    final sqlUser = uri.queryParameters['sqlUser']?.trim() ?? '';
    final sqlPass = uri.queryParameters['sqlPass'] ?? '';
    final appUser = uri.queryParameters['appUser']?.trim() ?? '';
    final appPass = uri.queryParameters['appPass'] ?? '';

    final creds = TenantLoginCredentials(
      databaseName: db,
      sqlUserId: sqlUser,
      sqlPassword: sqlPass,
      appUserName: appUser,
      appPassword: appPass,
    );
    return creds.isComplete ? creds : null;
  }

  static TenantLoginCredentials? _tryParseEmbeddedCredentials(String input) {
    if (!input.startsWith('{')) return null;
    final data = _tryDecode(input);
    if (data == null) return null;

    // JSON v2 chỉ có token — không phải credentials đủ
    final version = data['version'] ?? data['Version'];
    final hasTokenOnly = (data['token'] ?? data['Token']) != null &&
        (data['databaseName'] ?? data['DatabaseName']) == null;
    if (version == 2 && hasTokenOnly) return null;

    final creds = _fromPayloadMap(data);
    return creds.isComplete ? creds : null;
  }

  static (String token, String? tokenUrl) _parseTokenInput(String input) {
    if (!input.startsWith('{')) {
      return (input, null);
    }
    final data = _tryDecode(input);
    if (data == null) return (input, null);

    final version = data['version'] ?? data['Version'];
    final token = (data['token'] ?? data['Token'])?.toString().trim() ?? '';
    final tokenUrl =
        (data['tokenUrl'] ?? data['TokenUrl'])?.toString().trim();
    if (version == 2 && token.isNotEmpty) {
      return (token, (tokenUrl == null || tokenUrl.isEmpty) ? null : tokenUrl);
    }
    return (input, null);
  }

  static TenantLoginCredentials _fromPayloadMap(Map<String, dynamic> data) {
    String pick(String a, String b) =>
        (data[a] ?? data[b])?.toString().trim() ?? '';

    // loginUrl trong payload cũng có thể chứa 5 field
    final loginUrl = pick('loginUrl', 'LoginUrl');
    if (loginUrl.isNotEmpty) {
      final fromUrl = _tryParseLoginUrl(loginUrl);
      if (fromUrl != null) return fromUrl;
    }

    return TenantLoginCredentials(
      databaseName: pick('databaseName', 'DatabaseName'),
      sqlUserId: pick('sqlUserId', 'SqlUserId'),
      sqlPassword: (data['sqlPassword'] ?? data['SqlPassword'])?.toString() ??
          '',
      appUserName: pick('appUserName', 'AppUserName'),
      appPassword: (data['appPassword'] ?? data['AppPassword'])?.toString() ??
          '',
    );
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }
}
