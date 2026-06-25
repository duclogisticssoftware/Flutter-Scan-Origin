import 'package:qrscan_app/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'jwt';
  static const String _lastLoginKey = 'last_login';
  static const String _appUserNameKey = 'app_user_name';
  static const String _databaseNameKey = 'database_name';
  static const int _tokenValidHours = 24; // Token hợp lệ trong 24 giờ

  // Kiểm tra xem user có đã đăng nhập chưa
  static Future<bool> isAuthenticated() async {
    try {
      final token = await AppStorage.instance.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        return false;
      }

      // Kiểm tra token có hết hạn không (offline check)
      final lastLogin = await AppStorage.instance.read(key: _lastLoginKey);
      if (lastLogin != null) {
        final lastLoginTime = DateTime.tryParse(lastLogin);
        if (lastLoginTime != null) {
          final now = DateTime.now();
          final hoursSinceLogin = now.difference(lastLoginTime).inHours;
          if (hoursSinceLogin > _tokenValidHours) {
            // Token đã hết hạn, xóa token
            await logout();
            return false;
          }
        }
      }

      // Kiểm tra token với server (online check)
      return await _validateTokenWithServer(token);
    } catch (e) {
      return false;
    }
  }

  // Validate token với server
  static Future<bool> _validateTokenWithServer(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBase/api/auth/validate-token'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'QRScan-Vinalink-Web/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      // Nếu không kết nối được server, coi như token vẫn hợp lệ
      // (để tránh logout khi mất mạng tạm thời)
      return true;
    }
  }

  // Lưu token sau khi login thành công
  static Future<void> saveToken(
    String token, {
    String? appUserName,
    String? databaseName,
  }) async {
    await AppStorage.instance.write(key: _tokenKey, value: token);
    await AppStorage.instance.write(
      key: _lastLoginKey,
      value: DateTime.now().toIso8601String(),
    );
    if (appUserName != null && appUserName.isNotEmpty) {
      await AppStorage.instance.write(key: _appUserNameKey, value: appUserName);
    }
    if (databaseName != null && databaseName.isNotEmpty) {
      await AppStorage.instance.write(key: _databaseNameKey, value: databaseName);
    }
  }

  static Future<void> loginTenant({
    required String databaseName,
    required String sqlUserId,
    required String sqlPassword,
    required String appUserName,
    required String appPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$apiBase/api/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'QRScan-Vinalink-Web/1.0',
          },
          body: jsonEncode({
            'databaseName': databaseName,
            'sqlUserId': sqlUserId,
            'sqlPassword': sqlPassword,
            'appUserName': appUserName,
            'appPassword': appPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    await _handleLoginResponse(response);
  }

  static Future<void> loginByQr(String token) async {
    final response = await http
        .post(
          Uri.parse('$apiBase/api/auth/login-by-qr'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'QRScan-Vinalink-Web/1.0',
          },
          body: jsonEncode({'token': token}),
        )
        .timeout(const Duration(seconds: 15));

    await _handleLoginResponse(response);
  }

  static Future<void> _handleLoginResponse(http.Response response) async {
    final data = _tryDecodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response, data));
    }

    final token =
        (data?['token'] ??
                data?['access_token'] ??
                data?['accessToken'] ??
                data?['jwt'])
            as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final user = data?['user'];
    await saveToken(
      token,
      appUserName: user is Map ? user['appUserName'] as String? : null,
      databaseName: user is Map ? user['databaseName'] as String? : null,
    );
  }

  static Map<String, dynamic>? _tryDecodeJson(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(
    http.Response response,
    Map<String, dynamic>? data,
  ) {
    final message = data?['message'] as String?;
    final error = data?['error'] as String?;
    return message ?? error ?? 'Đăng nhập thất bại (${response.statusCode})';
  }

  // Lấy token hiện tại
  static Future<String?> getToken() async {
    return await AppStorage.instance.read(key: _tokenKey);
  }

  static Future<String?> getAppUserName() async {
    return await AppStorage.instance.read(key: _appUserNameKey);
  }

  static Future<String?> getDatabaseName() async {
    return await AppStorage.instance.read(key: _databaseNameKey);
  }

  // Logout
  static Future<void> logout() async {
    await AppStorage.instance.delete(key: _tokenKey);
    await AppStorage.instance.delete(key: _lastLoginKey);
    await AppStorage.instance.delete(key: _appUserNameKey);
    await AppStorage.instance.delete(key: _databaseNameKey);
  }

  // Kiểm tra kết nối mạng
  static Future<bool> hasNetworkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBase/api/health'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'QRScan-Vinalink-Web/1.0',
            },
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
