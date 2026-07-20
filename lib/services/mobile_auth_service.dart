import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/models/mobile_auth_models.dart';

class MobileAuthService {
  static const String _tokenKey = 'mobile_jwt';
  static const String _expiresKey = 'mobile_expires_at';
  static const String _tenantIdKey = 'mobile_tenant_id';
  static const String _databaseNameKey = 'mobile_database_name';
  static const String _usrIdKey = 'mobile_usr_id';
  static const String _nameKey = 'mobile_name';
  static const String _usrKey = 'mobile_usr';
  static const String _fcmTokenKey = 'fcm_device_token';

  static Future<MobileLoginResult> login({
    required String databaseName,
    required String sqlUserId,
    required String sqlPassword,
    required String appUserName,
    required String appPassword,
  }) async {
    final loginUrl = '$mobileApiBase/api/mobile/auth/login';
    final response = await http
        .post(
          Uri.parse(loginUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'LMS-Mobile/1.0',
          },
          body: jsonEncode({
            'databaseName': databaseName,
            'sqlUserId': sqlUserId,
            'sqlPassword': sqlPassword,
            'appUserName': appUserName,
            'appPassword': appPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint(
      '[MobileAuth] POST $loginUrl → HTTP ${response.statusCode}, '
      'body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
    );

    final data = _tryDecode(response.body);
    if (data == null) {
      final preview = response.body.trim();
      final looksHtml = preview.startsWith('<!') ||
          preview.toLowerCase().startsWith('<html');
      throw Exception(
        looksHtml || response.statusCode == 302
            ? 'API mobile chưa có trên server ($mobileApiBase/api/mobile/...). '
                'HTTP ${response.statusCode} — nhận HTML thay vì JSON. '
                'Cần deploy endpoint /api/mobile/auth/login trên NVOAMASIS.'
            : 'Đăng nhập mobile thất bại (HTTP ${response.statusCode}): '
                '${preview.isEmpty ? "(empty body)" : preview.substring(0, preview.length.clamp(0, 180))}',
      );
    }

    final result = MobileLoginResult.fromJson(data);
    if (!result.flag ||
        result.accessToken == null ||
        result.accessToken!.isEmpty) {
      throw Exception(
        result.message.isNotEmpty
            ? result.message
            : 'Đăng nhập mobile thất bại',
      );
    }

    await saveSession(result, fallbackDatabaseName: databaseName);
    return result;
  }

  static Future<void> saveSession(
    MobileLoginResult result, {
    String? fallbackDatabaseName,
  }) async {
    await AppStorage.instance.write(
      key: _tokenKey,
      value: result.accessToken,
    );
    if (result.expiresAtUtc != null) {
      await AppStorage.instance.write(
        key: _expiresKey,
        value: result.expiresAtUtc!.toUtc().toIso8601String(),
      );
    }
    if (result.tenantId != null) {
      await AppStorage.instance.write(
        key: _tenantIdKey,
        value: result.tenantId,
      );
    }
    final dbName = (result.databaseName?.isNotEmpty == true)
        ? result.databaseName
        : fallbackDatabaseName;
    if (dbName != null && dbName.isNotEmpty) {
      await AppStorage.instance.write(key: _databaseNameKey, value: dbName);
    }
    if (result.usrId != null) {
      await AppStorage.instance.write(key: _usrIdKey, value: result.usrId);
    }
    if (result.name != null) {
      await AppStorage.instance.write(key: _nameKey, value: result.name);
    }
    if (result.usr != null) {
      await AppStorage.instance.write(key: _usrKey, value: result.usr);
    }
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    final expires = await AppStorage.instance.read(key: _expiresKey);
    if (expires != null) {
      final expiresAt = DateTime.tryParse(expires);
      if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
        await clearSession();
        return false;
      }
    }

    return me();
  }

  static Future<bool> me() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await http
          .get(
            Uri.parse('$mobileApiBase/api/mobile/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'LMS-Mobile/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      // Mất mạng tạm thời: giữ session nếu chưa hết hạn local
      return true;
    }
  }

  static Future<String?> getAccessToken() =>
      AppStorage.instance.read(key: _tokenKey);

  static Future<String?> getUsrId() =>
      AppStorage.instance.read(key: _usrIdKey);

  static Future<String?> getTenantId() =>
      AppStorage.instance.read(key: _tenantIdKey);

  static Future<String?> getDatabaseName() =>
      AppStorage.instance.read(key: _databaseNameKey);

  static Future<String?> getDisplayName() =>
      AppStorage.instance.read(key: _nameKey);

  static Future<void> saveFcmToken(String token) =>
      AppStorage.instance.write(key: _fcmTokenKey, value: token);

  static Future<String?> getFcmToken() =>
      AppStorage.instance.read(key: _fcmTokenKey);

  static Future<void> clearFcmToken() =>
      AppStorage.instance.delete(key: _fcmTokenKey);

  static Future<void> clearSession() async {
    await AppStorage.instance.delete(key: _tokenKey);
    await AppStorage.instance.delete(key: _expiresKey);
    await AppStorage.instance.delete(key: _tenantIdKey);
    await AppStorage.instance.delete(key: _databaseNameKey);
    await AppStorage.instance.delete(key: _usrIdKey);
    await AppStorage.instance.delete(key: _nameKey);
    await AppStorage.instance.delete(key: _usrKey);
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : null;
    } catch (_) {
      return null;
    }
  }
}
