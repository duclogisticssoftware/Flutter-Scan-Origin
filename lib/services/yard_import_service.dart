import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/services/auth_service.dart';

class YardImportService {
  static Future<Map<String, dynamic>> preview834({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('834/preview', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> import834({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('834/import', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> preview835({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('835/preview', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> import835({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('835/import', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> preview836({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('836/preview', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> import836({
    required Uint8List fileBytes,
    required String fileName,
    required String depot,
  }) async {
    return _multipart('836/import', fileBytes, fileName, depot);
  }

  static Future<Map<String, dynamic>> preview837({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return _multipart('837/preview', fileBytes, fileName, 'SP-ITC');
  }

  static Future<Map<String, dynamic>> import837({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return _multipart('837/import', fileBytes, fileName, 'SP-ITC');
  }

  static Future<({Uint8List bytes, String name})?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;
    return (bytes: file.bytes!, name: file.name);
  }

  static Future<Map<String, dynamic>> _multipart(
    String path,
    Uint8List fileBytes,
    String fileName,
    String depot,
  ) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$apiBase/api/YardImport/$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['depot'] = depot;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    final streamed = await request.send().timeout(const Duration(minutes: 5));
    final response = await http.Response.fromStream(streamed);
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message']?.toString() ?? 'Import failed (${response.statusCode})');
    }
    return body;
  }
}
