import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:qrscan_app/services/mobile_auth_service.dart';

class MobileHttpService {
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'LMS-Mobile/1.0',
  };

  static Future<Map<String, String>> _headers([
    Map<String, String>? extra,
  ]) async {
    final headers = Map<String, String>.from(_defaultHeaders);
    final token = await MobileAuthService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return http
        .get(Uri.parse(url), headers: await _headers(headers))
        .timeout(timeout ?? const Duration(seconds: 20));
  }

  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return http
        .post(
          Uri.parse(url),
          headers: await _headers(headers),
          body: body,
        )
        .timeout(timeout ?? const Duration(seconds: 20));
  }

  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final request = http.Request('DELETE', Uri.parse(url));
    request.headers.addAll(await _headers(headers));
    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }
    final streamed = await request
        .send()
        .timeout(timeout ?? const Duration(seconds: 20));
    return http.Response.fromStream(streamed);
  }

  static bool isSuccess(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  static Map<String, dynamic>? tryDecode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : null;
    } catch (_) {
      return null;
    }
  }

  static String getErrorMessage(http.Response response) {
    final data = tryDecode(response);
    return data?['message'] as String? ??
        data?['error'] as String? ??
        'Request failed (${response.statusCode})';
  }
}
