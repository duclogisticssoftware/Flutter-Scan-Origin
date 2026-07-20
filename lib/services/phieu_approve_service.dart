import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/models/phieu_approve_detail.dart';
import 'package:qrscan_app/services/mobile_http_service.dart';

class PhieuApproveService {
  /// Ghép URL bằng pathSegments — encode 1 lần, tránh token bị lệch → server 500.
  static Uri _uri(String phieuToken, [String? action]) {
    final base = Uri.parse(mobileApiBase);
    final segments = <String>[
      ...base.pathSegments.where((s) => s.isNotEmpty),
      'api',
      'mobile',
      'phieu-approve',
      phieuToken.trim(),
      if (action != null && action.isNotEmpty) action,
    ];
    return base.replace(pathSegments: segments);
  }

  static Future<PhieuApproveDetail> getDetail(String phieuToken) async {
    final token = phieuToken.trim();
    if (token.isEmpty) {
      throw Exception('Thiếu phieuToken — không mở được trang duyệt.');
    }

    final uri = _uri(token);
    final response = await MobileHttpService.get(uri.toString());
    debugPrint(
      '[PhieuApprove] GET $uri → HTTP ${response.statusCode} '
      'body=${_preview(response.body)}',
    );

    if (response.statusCode >= 500) {
      throw Exception(_serverErrorMessage(response, 'tải chi tiết phiếu'));
    }

    final data = MobileHttpService.tryDecode(response);
    if (!MobileHttpService.isSuccess(response) || data == null) {
      throw Exception(MobileHttpService.getErrorMessage(response));
    }

    final detail = PhieuApproveDetail.fromJson(data);
    debugPrint(
      '[PhieuApprove] detail canDecide=${detail.canDecide} '
      'alreadyDecided=${detail.alreadyDecided} soPhieu=${detail.soPhieu}',
    );
    return detail;
  }

  static Future<PhieuDecideResult> decide({
    required String phieuToken,
    required bool approve,
    String? remarks,
  }) async {
    final token = phieuToken.trim();
    if (token.isEmpty) {
      throw Exception('Thiếu phieuToken — không gửi được quyết định.');
    }

    final uri = _uri(token, 'decide');
    final payload = <String, dynamic>{'approve': approve};
    if (!approve) {
      payload['remarks'] = remarks?.trim() ?? '';
    }

    final response = await MobileHttpService.post(
      uri.toString(),
      body: jsonEncode(payload),
    );
    debugPrint(
      '[PhieuApprove] POST $uri body=$payload → HTTP ${response.statusCode} '
      'body=${_preview(response.body)}',
    );

    if (response.statusCode >= 500) {
      throw Exception(_serverErrorMessage(response, 'duyệt phiếu'));
    }

    final data = MobileHttpService.tryDecode(response);
    if (data == null) {
      throw Exception(
        'Không đọc được phản hồi duyệt (HTTP ${response.statusCode}). '
        '${_preview(response.body)}',
      );
    }
    final result = PhieuDecideResult.fromJson(data);
    if (!MobileHttpService.isSuccess(response) || !result.flag) {
      throw Exception(
        result.message.isNotEmpty
            ? result.message
            : MobileHttpService.getErrorMessage(response),
      );
    }
    return result;
  }

  static String _serverErrorMessage(http.Response response, String action) {
    final data = MobileHttpService.tryDecode(response);
    final serverMsg = data?['message']?.toString() ??
        data?['Message']?.toString() ??
        data?['title']?.toString() ??
        data?['detail']?.toString();

    final buf = StringBuffer(
      'Lỗi server HTTP ${response.statusCode} khi $action.',
    );
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      buf.write('\n$serverMsg');
    }
    buf.write(
      '\n\nĐây là lỗi phía NVOAMASIS (không phải Flutter UI). '
      'Kiểm tra token phiếu / log server, hoặc mở lại phiếu trên web.',
    );
    return buf.toString();
  }

  static String _preview(String body) {
    final t = body.trim();
    if (t.isEmpty) return '(empty)';
    return t.length > 240 ? '${t.substring(0, 240)}…' : t;
  }
}
