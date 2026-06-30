import 'dart:convert';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/services/http_service.dart';

class ContainerInventoryService {
  static Future<Map<String, dynamic>> getDashboard({
    String search = '',
    String? sourceFilter,
    String? agentFilter,
    String? lineFilter,
    String? depotFilter,
    String? sizeFilter,
    String? statusFilter,
    String? felFilter,
    int? minDemDaysFilter,
    int? minDetDaysFilter,
    bool excludeDamaged = false,
    int demFreeDays = 0,
    int detFreeDays = 0,
  }) async {
    final params = <String, String>{
      'search': search,
      'excludeDamaged': excludeDamaged.toString(),
      'demFreeDays': demFreeDays.toString(),
      'detFreeDays': detFreeDays.toString(),
    };
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) params[key] = value;
    }

    add('sourceFilter', sourceFilter);
    add('agentFilter', agentFilter);
    add('lineFilter', lineFilter);
    add('depotFilter', depotFilter);
    add('sizeFilter', sizeFilter);
    add('statusFilter', statusFilter);
    add('felFilter', felFilter);
    if (minDemDaysFilter != null) params['minDemDaysFilter'] = '$minDemDaysFilter';
    if (minDetDaysFilter != null) params['minDetDaysFilter'] = '$minDetDaysFilter';

    final uri = Uri.parse('$apiBase/api/ContainerInventory/dashboard')
        .replace(queryParameters: params);
    final response = await HttpService.get(uri.toString(), timeout: const Duration(seconds: 120));
    if (!HttpService.isSuccess(response)) {
      throw Exception(HttpService.getErrorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<List<dynamic>> getContainerEvents(String containerKey) async {
    final encoded = Uri.encodeComponent(containerKey);
    final response = await HttpService.get(
      '$apiBase/api/ContainerInventory/events/$encoded',
      timeout: const Duration(seconds: 60),
    );
    if (!HttpService.isSuccess(response)) {
      throw Exception(HttpService.getErrorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>?) ?? [];
  }

  static Future<List<String>> getDepots() async {
    final response = await HttpService.get('$apiBase/api/ContainerInventory/depots');
    if (!HttpService.isSuccess(response)) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }

  static String buildExportCsvUrl(ContainerInventoryQuery q) {
    final params = q.toQueryParams();
    return Uri.parse('$apiBase/api/ContainerInventory/export-csv')
        .replace(queryParameters: params)
        .toString();
  }
}

class ContainerInventoryQuery {
  String search = '';
  String? sourceFilter;
  String? agentFilter;
  String? lineFilter;
  String? depotFilter;
  String? sizeFilter;
  String? statusFilter;
  String? felFilter;
  int? minDemDaysFilter;
  int? minDetDaysFilter;
  bool excludeDamaged = false;
  int demFreeDays = 0;
  int detFreeDays = 0;

  Map<String, String> toQueryParams() => {
        'search': search,
        'excludeDamaged': excludeDamaged.toString(),
        'demFreeDays': demFreeDays.toString(),
        'detFreeDays': detFreeDays.toString(),
        if (sourceFilter != null && sourceFilter!.isNotEmpty) 'sourceFilter': sourceFilter!,
        if (agentFilter != null && agentFilter!.isNotEmpty) 'agentFilter': agentFilter!,
        if (lineFilter != null && lineFilter!.isNotEmpty) 'lineFilter': lineFilter!,
        if (depotFilter != null && depotFilter!.isNotEmpty) 'depotFilter': depotFilter!,
        if (sizeFilter != null && sizeFilter!.isNotEmpty) 'sizeFilter': sizeFilter!,
        if (statusFilter != null && statusFilter!.isNotEmpty) 'statusFilter': statusFilter!,
        if (felFilter != null && felFilter!.isNotEmpty) 'felFilter': felFilter!,
        if (minDemDaysFilter != null) 'minDemDaysFilter': '$minDemDaysFilter',
        if (minDetDaysFilter != null) 'minDetDaysFilter': '$minDetDaysFilter',
      };
}
