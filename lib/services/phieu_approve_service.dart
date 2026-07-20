import 'dart:convert';

import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/models/phieu_approve_detail.dart';
import 'package:qrscan_app/services/mobile_http_service.dart';

class PhieuApproveService {
  static Future<PhieuApproveDetail> getDetail(String phieuToken) async {
    final response = await MobileHttpService.get(
      '$mobileApiBase/api/mobile/phieu-approve/$phieuToken',
    );
    final data = MobileHttpService.tryDecode(response);
    if (!MobileHttpService.isSuccess(response) || data == null) {
      throw Exception(MobileHttpService.getErrorMessage(response));
    }
    return PhieuApproveDetail.fromJson(data);
  }

  static Future<PhieuDecideResult> decide({
    required String phieuToken,
    required bool approve,
    String? remarks,
  }) async {
    final response = await MobileHttpService.post(
      '$mobileApiBase/api/mobile/phieu-approve/$phieuToken/decide',
      body: jsonEncode({
        'approve': approve,
        'remarks': approve ? null : remarks,
      }),
    );
    final data = MobileHttpService.tryDecode(response);
    if (data == null) {
      throw Exception(MobileHttpService.getErrorMessage(response));
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
}
