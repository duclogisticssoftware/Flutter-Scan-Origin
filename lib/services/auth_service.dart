import 'package:qrscan_app/config/app_config.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _tokenKey = 'jwt';
  static const String _lastLoginKey = 'last_login';
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
  static Future<void> saveToken(String token) async {
    await AppStorage.instance.write(key: _tokenKey, value: token);
    await AppStorage.instance.write(
      key: _lastLoginKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  // Lấy token hiện tại
  static Future<String?> getToken() async {
    return await AppStorage.instance.read(key: _tokenKey);
  }

  // Logout
  static Future<void> logout() async {
    await AppStorage.instance.delete(key: _tokenKey);
    await AppStorage.instance.delete(key: _lastLoginKey);
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
