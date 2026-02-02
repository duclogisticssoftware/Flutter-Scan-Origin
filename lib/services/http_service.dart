import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qrscan_app/services/auth_service.dart';

class HttpService {
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'QRScan-Vinalink-Web/1.0',
  };

  /// GET request với authentication
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final token = await AuthService.getToken();
    final requestHeaders = Map<String, String>.from(_defaultHeaders);
    
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return await http
        .get(
          Uri.parse(url),
          headers: requestHeaders,
        )
        .timeout(timeout ?? const Duration(seconds: 15));
  }

  /// POST request với authentication
  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final token = await AuthService.getToken();
    final requestHeaders = Map<String, String>.from(_defaultHeaders);
    
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return await http
        .post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        )
        .timeout(timeout ?? const Duration(seconds: 15));
  }

  /// PUT request với authentication
  static Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final token = await AuthService.getToken();
    final requestHeaders = Map<String, String>.from(_defaultHeaders);
    
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return await http
        .put(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        )
        .timeout(timeout ?? const Duration(seconds: 15));
  }

  /// DELETE request với authentication
  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final token = await AuthService.getToken();
    final requestHeaders = Map<String, String>.from(_defaultHeaders);
    
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return await http
        .delete(
          Uri.parse(url),
          headers: requestHeaders,
        )
        .timeout(timeout ?? const Duration(seconds: 15));
  }

  /// Kiểm tra response có thành công không
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Kiểm tra response có phải lỗi authentication không
  static bool isAuthError(http.Response response) {
    return response.statusCode == 401;
  }

  /// Lấy error message từ response
  static String getErrorMessage(http.Response response) {
    try {
      final body = response.body;
      if (body.isNotEmpty) {
        // Thử parse JSON để lấy message
        final data = jsonDecode(body);
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
        if (data is Map && data['error'] is String) {
          return data['error'] as String;
        }
      }
    } catch (e) {
      // Nếu không parse được JSON, trả về status code
    }
    
    return 'Request failed with status ${response.statusCode}';
  }
}
