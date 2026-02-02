// Web-specific configuration for QR Scan App
// This file handles web-specific settings and CORS issues

import 'package:flutter/foundation.dart';

class WebConfig {
  static bool get isWeb => kIsWeb;

  // Web-specific API configuration
  static const Map<String, String> webHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'QRScan-Vinalink-Web/1.0',
    'X-Requested-With': 'XMLHttpRequest', // Helps with CORS
  };

  // CORS-friendly headers for web requests
  static Map<String, String> getCorsHeaders() {
    return Map<String, String>.from(webHeaders);
  }

  // Add authentication header if token exists
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = getCorsHeaders();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Web-specific error messages
  static String getWebErrorMessage(dynamic error) {
    if (isWeb) {
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('cors')) {
        return 'Lỗi CORS: Server không cho phép truy cập từ web. Vui lòng liên hệ admin.';
      }

      if (errorString.contains('network')) {
        return 'Lỗi mạng: Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet.';
      }

      if (errorString.contains('timeout')) {
        return 'Timeout: Server phản hồi quá chậm. Vui lòng thử lại.';
      }

      if (errorString.contains('ssl') || errorString.contains('certificate')) {
        return 'Lỗi SSL: Vấn đề với chứng chỉ bảo mật. Vui lòng liên hệ admin.';
      }
    }

    return 'Lỗi: $error';
  }

  // Check if running in development mode
  static bool get isDevelopment {
    if (isWeb) {
      // Check if running on localhost
      return Uri.base.host == 'localhost' ||
          Uri.base.host == '127.0.0.1' ||
          Uri.base.host.contains('ngrok');
    }
    return false;
  }

  // Get base URL for API calls
  static String getApiBaseUrl() {
    if (isWeb && isDevelopment) {
      // For development, you might want to use a different API URL
      return 'https://qr.logisticssoftware.vn';
    }
    return 'https://qr.logisticssoftware.vn';
  }
}
