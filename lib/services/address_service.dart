import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Lấy địa chỉ từ tọa độ latitude và longitude
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&addressdetails=1',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'QRScan Vinalink App'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractAddress(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Trích xuất địa chỉ từ response của Nominatim
  static String? _extractAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    // Tạo địa chỉ từ các thành phần có sẵn
    final parts = <String>[];

    // Thêm tên đường/số nhà
    if (address['house_number'] != null && address['road'] != null) {
      parts.add('${address['house_number']} ${address['road']}');
    } else if (address['road'] != null) {
      parts.add(address['road']);
    }

    // Thêm phường/xã
    if (address['suburb'] != null) {
      parts.add(address['suburb']);
    } else if (address['neighbourhood'] != null) {
      parts.add(address['neighbourhood']);
    }

    // Thêm quận/huyện
    if (address['city_district'] != null) {
      parts.add(address['city_district']);
    } else if (address['county'] != null) {
      parts.add(address['county']);
    }

    // Thêm thành phố/tỉnh
    if (address['city'] != null) {
      parts.add(address['city']);
    } else if (address['state'] != null) {
      parts.add(address['state']);
    }

    // Thêm quốc gia
    if (address['country'] != null) {
      parts.add(address['country']);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Lấy địa chỉ ngắn gọn (chỉ tên đường và khu vực)
  static Future<String?> getShortAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&addressdetails=1&zoom=18',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'QRScan Vinalink App'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractShortAddress(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Trích xuất địa chỉ ngắn gọn
  static String? _extractShortAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    final parts = <String>[];

    // Thêm tên đường/số nhà
    if (address['house_number'] != null && address['road'] != null) {
      parts.add('${address['house_number']} ${address['road']}');
    } else if (address['road'] != null) {
      parts.add(address['road']);
    }

    // Thêm phường/xã
    if (address['suburb'] != null) {
      parts.add(address['suburb']);
    } else if (address['neighbourhood'] != null) {
      parts.add(address['neighbourhood']);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
