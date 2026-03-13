import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qrscan_app/utils/save_file_stub.dart'
    if (dart.library.html) 'package:qrscan_app/utils/save_file_web.dart'
    as save_file;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/services/http_service.dart';
import 'package:qrscan_app/services/inventory_export_service.dart'
    show InventoryExportRow, exportInventoryToExcel, exportInventoryToPdf;
import 'package:qrscan_app/utils/theme_colors.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _containers = [];
  String? _error;

  int _inDepotCount = 0;
  int _waitingPortArrivalCount = 0;
  int _arrivedAtPortCount = 0;
  int _inTransitCount = 0;

  List<String> _distinctSizeTypes = [];
  List<_InventoryGroupRow> _inDepotRows = [];
  List<_InventoryGroupRow> _inPortRows = [];

  final TextEditingController _searchInDepotController =
      TextEditingController();
  final TextEditingController _searchInPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchInDepotController.dispose();
    _searchInPortController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await HttpService.get(
        '$apiBase/api/Container/container',
      );

      if (!mounted) return;

      if (HttpService.isSuccess(response)) {
        try {
          final body = jsonDecode(response.body);
          if (body is! Map<String, dynamic>) {
            setState(() {
              _containers = [];
              _loading = false;
              _buildDashboard();
            });
            return;
          }
          final data = body['data'];
          List<dynamic> rawList = [];
          if (data is List) {
            rawList = data;
          } else if (data is Map) {
            rawList = data.values.toList();
          }
          final list = <Map<String, dynamic>>[];
          for (var i = 0; i < rawList.length; i++) {
            final e = rawList[i];
            if (e is Map<String, dynamic>) {
              list.add(e);
            } else if (e is Map) {
              list.add(Map<String, dynamic>.from(e));
            } else {
              list.add(<String, dynamic>{});
            }
          }
          setState(() {
            _containers = list;
            _loading = false;
            _buildDashboard();
          });
        } catch (parseError) {
          if (mounted) {
            setState(() {
              _error = 'Lỗi parse: $parseError';
              _loading = false;
            });
          }
        }
      } else {
        setState(() {
          _error = HttpService.getErrorMessage(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi: $e';
          _loading = false;
        });
      }
    }
  }

  String _nvoccStatus(Map<String, dynamic> c) {
    final v =
        c['nvocC_Status'] ??
        c['nvoCC_Status'] ??
        c['NVOCC_Status'] ??
        c['nvoCCStatus'];
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty) return '';
    return s.split(RegExp(r'\s+')).join(' ');
  }

  String _inDepot(Map<String, dynamic> c) {
    final v = c['in_Depot'] ?? c['In_Depot'] ?? c['inDepot'];
    if (v != null) return v.toString().trim();
    return '';
  }

  String _inPort(Map<String, dynamic> c) {
    final v = c['in_Port'] ?? c['In_Port'] ?? c['inPort'];
    if (v != null) return v.toString().trim();
    return '';
  }

  String _sizeType(Map<String, dynamic> c) {
    final v =
        c['ctN_SIZE_TYPE'] ??
        c['ctn_SIZE_TYPE'] ??
        c['CTN_SIZE_TYPE'] ??
        c['ctnSizeType'];
    if (v != null) return v.toString().trim();
    return '';
  }

  bool _decommission(Map<String, dynamic> c) {
    final v = c['decommision'] ?? c['Decommision'];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  static int _getLeadingNumber(String? sizeType) {
    if (sizeType == null || sizeType.trim().isEmpty) return 0x7FFFFFFF;
    final s = sizeType.trim();
    int i = 0;
    while (i < s.length && s[i].contains(RegExp(r'[0-9]'))) i++;
    if (i == 0) return 0x7FFFFFFF;
    return int.tryParse(s.substring(0, i)) ?? 0x7FFFFFFF;
  }

  static String _getSuffix(String? sizeType) {
    if (sizeType == null || sizeType.trim().isEmpty) return '';
    final s = sizeType.trim();
    int i = 0;
    while (i < s.length && s[i].contains(RegExp(r'[0-9]'))) i++;
    return i < s.length ? s.substring(i) : '';
  }

  void _buildDashboard() {
    try {
      const inDepotStatus = 'in depot';
      const waitingStatus = 'waiting port arrival';
      const arrivedStatus = 'arrived at port';
      const inTransitStatus = 'in transit';

      _inDepotCount = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == inDepotStatus)
          .length;
      _waitingPortArrivalCount = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == waitingStatus)
          .length;
      _arrivedAtPortCount = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == arrivedStatus)
          .length;
      _inTransitCount = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == inTransitStatus)
          .length;

      // Chỉ lấy "In Depot" và "Arrived at Port" giống Razor containersForTables
      final forTables = _containers.where((c) {
        final s = _nvoccStatus(c).toLowerCase();
        return s == inDepotStatus || s == arrivedStatus;
      }).toList();

      // DistinctSizeTypes từ forTables, unique ignore case (giữ lần đầu), rồi sort giống Razor
      final sizeTypeList = <String>[];
      for (final c in forTables) {
        final st = _sizeType(c);
        if (st.isEmpty) continue;
        final lower = st.toLowerCase();
        if (sizeTypeList.any((e) => e.toLowerCase() == lower)) continue;
        sizeTypeList.add(st);
      }
      _distinctSizeTypes = sizeTypeList
        ..sort((a, b) {
          final na = _getLeadingNumber(a);
          final nb = _getLeadingNumber(b);
          if (na != nb) return na.compareTo(nb);
          return _getSuffix(
            a,
          ).toLowerCase().compareTo(_getSuffix(b).toLowerCase());
        });

      final inDepotList = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == inDepotStatus)
          .toList();
      final inPortList = _containers
          .where((c) => _nvoccStatus(c).toLowerCase() == arrivedStatus)
          .toList();

      _inDepotRows = _buildGroupedRows(inDepotList, _inDepot);
      _inPortRows = _buildGroupedRows(inPortList, _inPort);
    } catch (e) {
      _inDepotCount = 0;
      _waitingPortArrivalCount = 0;
      _arrivedAtPortCount = 0;
      _inTransitCount = 0;
      _distinctSizeTypes = [];
      _inDepotRows = [];
      _inPortRows = [];
    }
  }

  /// Giống Razor BuildGroupedRows: GroupBy(keySelector), Location = null/whitespace ? "N/A" : key,
  /// SizeCounts = count theo CTN_SIZE_TYPE equals (ignore case), DecommissionCount = count Decommision == true.
  List<_InventoryGroupRow> _buildGroupedRows(
    List<Map<String, dynamic>> source,
    String Function(Map<String, dynamic>) keySelector,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final c in source) {
      final key = keySelector(c);
      final trimmed = key.trim();
      final locationKey = trimmed.isEmpty ? 'N/A' : trimmed;
      map.putIfAbsent(locationKey, () => []).add(c);
    }
    return map.entries.map((e) {
      final list = e.value;
      final sizeCounts = <String, int>{};
      for (final st in _distinctSizeTypes) {
        sizeCounts[st] = list
            .where((c) => _sizeType(c).toLowerCase() == st.toLowerCase())
            .length;
      }
      return _InventoryGroupRow(
        location: e.key,
        containerCount: list.length,
        sizeCounts: sizeCounts,
        decommissionCount: list.where(_decommission).length,
      );
    }).toList()..sort((a, b) => a.location.compareTo(b.location));
  }

  List<_InventoryGroupRow> get _filteredInDepotRows {
    final q = _searchInDepotController.text.trim().toLowerCase();
    if (q.isEmpty) return _inDepotRows;
    return _inDepotRows
        .where((r) => r.location.toLowerCase().contains(q))
        .toList();
  }

  List<_InventoryGroupRow> get _filteredInPortRows {
    final q = _searchInPortController.text.trim().toLowerCase();
    if (q.isEmpty) return _inPortRows;
    return _inPortRows
        .where((r) => r.location.toLowerCase().contains(q))
        .toList();
  }

  List<InventoryExportRow> _toExportRows(List<_InventoryGroupRow> rows) {
    return rows
        .map(
          (r) => InventoryExportRow(
            location: r.location,
            containerCount: r.containerCount,
            sizeCounts: Map<String, int>.from(r.sizeCounts),
            decommissionCount: r.decommissionCount,
          ),
        )
        .toList();
  }

  Future<void> _exportExcelDepot() async {
    await _exportExcel(
      sheetName: 'IN DEPOT Containers',
      locationHeader: 'IN DEPOT',
      rows: _filteredInDepotRows,
      fileName: 'IN DEPOT Containers.xlsx',
    );
  }

  Future<void> _exportExcelPort() async {
    await _exportExcel(
      sheetName: 'IN PORT Containers',
      locationHeader: 'IN PORT',
      rows: _filteredInPortRows,
      fileName: 'IN PORT Containers.xlsx',
    );
  }

  Future<void> _exportPdfDepot() async {
    try {
      final depot = _toExportRows(_filteredInDepotRows);
      const title = 'IN DEPOT Containers';
      const locationHeader = 'IN DEPOT';
      const decommissionHeader = 'Decommision';
      final bytes = await exportInventoryToPdf(
        rows: depot,
        sizeTypes: _distinctSizeTypes,
        title: title,
        locationHeader: locationHeader,
        decommissionHeader: decommissionHeader,
      );
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo file PDF.')),
          );
        }
        return;
      }
      final result = await save_file.saveFile(bytes, 'IN DEPOT Containers.pdf');
      if (mounted) {
        if (result != null && result.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu: $result')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xuất PDF (hoặc đã hủy lưu).')),
          );
        }
      }
    } catch (e) {
      debugPrint('[PDF] Lỗi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất PDF thất bại: $e')),
        );
      }
    }
  }

  Future<void> _exportPdfPort() async {
    try {
      final port = _toExportRows(_filteredInPortRows);
      const title = 'IN PORT Containers';
      const locationHeader = 'IN PORT';
      const decommissionHeader = 'Decommision';
      final bytes = await exportInventoryToPdf(
        rows: port,
        sizeTypes: _distinctSizeTypes,
        title: title,
        locationHeader: locationHeader,
        decommissionHeader: decommissionHeader,
      );
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo file PDF.')),
          );
        }
        return;
      }
      final result = await save_file.saveFile(bytes, 'IN PORT Containers.pdf');
      if (mounted) {
        if (result != null && result.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu: $result')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xuất PDF (hoặc đã hủy lưu).')),
          );
        }
      }
    } catch (e) {
      debugPrint('[PDF] Lỗi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất PDF thất bại: $e')),
        );
      }
    }
  }

  Future<void> _exportExcel({
    required String sheetName,
    required String locationHeader,
    required List<_InventoryGroupRow> rows,
    required String fileName,
  }) async {
    try {
      debugPrint(
        '[Excel] Bắt đầu xuất: sheetName=$sheetName, rows=${rows.length}, sizeTypes=${_distinctSizeTypes.length}',
      );
      final exportRows = _toExportRows(rows);
      debugPrint('[Excel] exportRows=${exportRows.length}');

      final bytes = exportInventoryToExcel(
        sheetName: sheetName,
        locationHeader: locationHeader,
        rows: exportRows,
        sizeTypes: _distinctSizeTypes,
      );
      debugPrint('[Excel] bytes=${bytes?.length ?? 0}');

      if (bytes == null || bytes.isEmpty) {
        debugPrint('[Excel] bytes null hoặc rỗng');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo file Excel.')),
          );
        }
        return;
      }

      final nameForDownload = fileName.endsWith('.xlsx')
          ? fileName
          : '$fileName.xlsx';
      debugPrint('[Excel] Gọi saveFile: fileName=$nameForDownload');
      final result = await save_file.saveFile(bytes, nameForDownload);
      debugPrint('[Excel] saveFile result: $result');

      if (mounted) {
        if (result != null && result.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã lưu: $result')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xuất Excel (hoặc đã hủy lưu).')),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('[Excel] Lỗi: $e');
      debugPrint('[Excel] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất Excel: $e')));
      }
    }
  }

  void _onExport(String table) {
    if (table == 'In Depot') {
      _exportExcelDepot();
    } else if (table == 'In Port') {
      _exportExcelPort();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export $table – tính năng sắp ra mắt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Container Inventory'),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _loading ? null : _loadData,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
              style: FilledButton.styleFrom(
                backgroundColor: ThemeColors.getPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
      body: _error != null
          ? _buildError()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTables(),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.9,
          children: [
            _summaryCard(
              'In Depot',
              'Container',
              _inDepotCount,
              Icons.inventory_2,
              Colors.blue,
            ),
            _summaryCard(
              'Waiting Port Arrival',
              'Container',
              _waitingPortArrivalCount,
              Icons.alarm_on,
              Colors.lightBlue,
            ),
            _summaryCard(
              'Arrived at Port',
              'Container',
              _arrivedAtPortCount,
              Icons.local_shipping,
              Colors.green,
            ),
            _summaryCard(
              'In Transit',
              'Container',
              _inTransitCount,
              Icons.directions_boat,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String subtitle,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTables() {
    return Column(
      children: [
        _buildInDepotTable(),
        const SizedBox(height: 24),
        _buildInPortTable(),
      ],
    );
  }

  Widget _buildInDepotTable() {
    return _buildTableCard(
      title: 'IN DEPOT',
      searchController: _searchInDepotController,
      rows: _filteredInDepotRows,
      onExport: () => _onExport('In Depot'),
      onExportPdf: _exportPdfDepot,
    );
  }

  Widget _buildInPortTable() {
    return _buildTableCard(
      title: 'IN PORT',
      searchController: _searchInPortController,
      rows: _filteredInPortRows,
      onExport: () => _onExport('In Port'),
      onExportPdf: _exportPdfPort,
    );
  }

  Widget _buildTableCard({
    required String title,
    required TextEditingController searchController,
    required List<_InventoryGroupRow> rows,
    required VoidCallback onExport,
    required VoidCallback onExportPdf,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _loading ? null : onExport,
                            icon: const Icon(Icons.table_chart, size: 18),
                            label: const Text('Excel'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('PDF'),
                            onPressed: _loading ? null : onExportPdf,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _loading ? null : onExport,
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('Excel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('PDF'),
                          onPressed: _loading ? null : onExportPdf,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  ThemeColors.getPrimaryColor(context).withOpacity(0.12),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'CONTAINER COUNT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._distinctSizeTypes.map(
                    (s) => DataColumn(
                      label: Text(
                        s,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Decommision',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: rows.map((r) => _rowToDataRow(r)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _rowToDataRow(_InventoryGroupRow r) {
    return DataRow(
      cells: [
        DataCell(Text(r.location)),
        DataCell(Text('${r.containerCount}')),
        ..._distinctSizeTypes.map(
          (st) => DataCell(Text('${r.getSizeCount(st)}')),
        ),
        DataCell(Text('${r.decommissionCount}')),
      ],
    );
  }
}

class _InventoryGroupRow {
  final String location;
  final int containerCount;
  final Map<String, int> sizeCounts;
  final int decommissionCount;

  _InventoryGroupRow({
    required this.location,
    required this.containerCount,
    required this.sizeCounts,
    required this.decommissionCount,
  });

  int getSizeCount(String sizeType) {
    if (sizeType.isEmpty) return 0;
    return sizeCounts[sizeType] ?? 0;
  }
}
