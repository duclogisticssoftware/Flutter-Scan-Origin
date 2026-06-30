import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qrscan_app/services/container_inventory_service.dart';
import 'package:qrscan_app/services/http_service.dart';
import 'package:qrscan_app/utils/save_file_stub.dart'
    if (dart.library.html) 'package:qrscan_app/utils/save_file_web.dart'
    as save_file;
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:qrscan_app/views/Inventory/yard_import_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic> _dashboard = {};
  final ContainerInventoryQuery _query = ContainerInventoryQuery();
  final TextEditingController _searchController = TextEditingController();
  bool _showDetailGrid = true;
  String? _selectedContainer;
  List<dynamic> _selectedEvents = [];

  int _detailPage = 0;
  int _detailRowsPerPage = 25;
  final ScrollController _detailVCtrl = ScrollController();
  final ScrollController _detailHCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailVCtrl.dispose();
    _detailHCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ContainerInventoryService.getDashboard(
        search: _query.search,
        sourceFilter: _query.sourceFilter,
        agentFilter: _query.agentFilter,
        lineFilter: _query.lineFilter,
        depotFilter: _query.depotFilter,
        sizeFilter: _query.sizeFilter,
        statusFilter: _query.statusFilter,
        felFilter: _query.felFilter,
        minDemDaysFilter: _query.minDemDaysFilter,
        minDetDaysFilter: _query.minDetDaysFilter,
        excludeDamaged: _query.excludeDamaged,
        demFreeDays: _query.demFreeDays,
        detFreeDays: _query.detFreeDays,
      );
      if (mounted) {
        setState(() {
          _dashboard = data;
          _loading = false;
          _detailPage = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<dynamic> _list(String key) => (_dashboard[key] as List<dynamic>?) ?? [];
  List<String> _options(String key) =>
      _list(key).map((e) => e.toString()).toList();
  int _int(String key) => (_dashboard[key] as num?)?.toInt() ?? 0;

  Future<void> _exportCsv() async {
    try {
      final token = await HttpService.get(
        ContainerInventoryService.buildExportCsvUrl(_query),
        timeout: const Duration(seconds: 120),
      );
      if (!HttpService.isSuccess(token)) {
        throw Exception(HttpService.getErrorMessage(token));
      }
      final bytes = Uint8List.fromList(utf8.encode(token.body));
      final name =
          'ContainerInventory_${DateTime.now().millisecondsSinceEpoch}.csv';
      await save_file.saveFile(bytes, name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xuất CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất CSV thất bại: $e')),
        );
      }
    }
  }

  Future<void> _openImport(String version, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YardImportScreen(version: version, title: title),
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _selectContainer(String containerKey) async {
    setState(() {
      _selectedContainer = containerKey;
      _selectedEvents = [];
    });
    try {
      final events = await ContainerInventoryService.getContainerEvents(containerKey);
      if (mounted) setState(() => _selectedEvents = events);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('8.3.3 Container Inventory'),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildFilters(),
                    const SizedBox(height: 12),
                    _buildSummaryCards(),
                    const SizedBox(height: 12),
                    _buildGroupTables(),
                    const SizedBox(height: 12),
                    _buildDetailSection(),
                    if (_selectedContainer != null) ...[
                      const SizedBox(height: 12),
                      _buildEventSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Thử lại')),
            ],
          ),
        ),
      );

  Widget _buildHeader() {
    final sourceInfo = _dashboard['sourceInfo']?.toString() ?? '';
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '8.3.3 Container Inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Statistics from yard/import tables – same logic as Blazor web.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (sourceInfo.isNotEmpty)
              Text('Data source: $sourceInfo', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('8.3.4 Import', Icons.upload_file, Colors.green,
                    () => _openImport('834', '8.3.4 Yard Movement')),
                _btn('8.3.5 Import', Icons.upload_file, Colors.blue,
                    () => _openImport('835', '8.3.5 Depot Container')),
                _btn('8.3.6 Import', Icons.upload_file, Colors.orange,
                    () => _openImport('836', '8.3.6 Stock In/Out APS')),
                _btn('8.3.7 SP-ITC', Icons.upload_file, Colors.blueGrey,
                    () => _openImport('837', '8.3.7 SP-ITC Yard')),
                _btn('Refresh', Icons.refresh, ThemeColors.getPrimaryColor(context),
                    _loading ? null : _loadData, loading: _loading),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _exportCsv,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('CSV'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback? onPressed,
      {bool loading = false}) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      icon: loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  _query.search = v;
                  _loadData();
                },
              ),
            ),
            _drop('Source', _query.sourceFilter, _options('sourceOptions'), (v) {
              _query.sourceFilter = v;
              _loadData();
            }),
            _drop('AGENT', _query.agentFilter, _options('agentOptions'), (v) {
              _query.agentFilter = v;
              _loadData();
            }),
            _drop('LINE', _query.lineFilter, _options('lineOptions'), (v) {
              _query.lineFilter = v;
              _loadData();
            }),
            _drop('DEPOT', _query.depotFilter, _options('depotOptions'), (v) {
              _query.depotFilter = v;
              _loadData();
            }),
            _drop('Size/Type', _query.sizeFilter,
                const ['20DC', '40HC', 'OTHER'], (v) {
              _query.sizeFilter = v;
              _loadData();
            }),
            _drop('Status', _query.statusFilter, const [
              'In Depot',
              'Waiting Port Arrival',
              'Arrived at Port',
              'In Transit',
            ], (v) {
              _query.statusFilter = v;
              _loadData();
            }),
            _drop('F/E/D', _query.felFilter, const ['E', 'F', 'D'], (v) {
              _query.felFilter = v;
              _loadData();
            }),
            FilterChip(
              label: const Text('Hide DAM'),
              selected: _query.excludeDamaged,
              onSelected: (v) {
                _query.excludeDamaged = v;
                _loadData();
              },
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: '${_query.demFreeDays}',
                decoration: const InputDecoration(labelText: 'DEM free', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  _query.demFreeDays = int.tryParse(v) ?? 0;
                  _loadData();
                },
              ),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: '${_query.detFreeDays}',
                decoration: const InputDecoration(labelText: 'DET free', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  _query.detFreeDays = int.tryParse(v) ?? 0;
                  _loadData();
                },
              ),
            ),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: _query.minDemDaysFilter?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'DEM ≥', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  _query.minDemDaysFilter = v.isEmpty ? null : int.tryParse(v);
                  _loadData();
                },
              ),
            ),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: _query.minDetDaysFilter?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'DET ≥', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (v) {
                  _query.minDetDaysFilter = v.isEmpty ? null : int.tryParse(v);
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value != null && items.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...items.map((v) => DropdownMenuItem(
                value: v,
                child: Text(v, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _kpi('In Depot', _int('inDepotCount'), Icons.inventory_2, Colors.blue),
        _kpi('Waiting Port', _int('waitingPortCount'), Icons.pending_actions, Colors.lightBlue),
        _kpi('Arrived at Port', _int('arrivedPortCount'), Icons.local_shipping, Colors.green),
        _kpi('In Transit', _int('inTransitCount'), Icons.directions_boat, Colors.orange),
      ],
    );
  }

  Widget _kpi(String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTables() {
    return Column(
      children: [
        _groupCard('IN DEPOT', _int('inDepotCount'), _list('inDepotGroups'), Colors.blue),
        const SizedBox(height: 12),
        _groupCard('ARRIVED AT PORT', _int('arrivedPortCount'), _list('arrivedPortGroups'), Colors.green),
        const SizedBox(height: 12),
        _groupCard('WAITING PORT ARRIVAL', _int('waitingPortCount'), _list('waitingPortGroups'), Colors.lightBlue),
        const SizedBox(height: 12),
        _groupCard('IN TRANSIT', _int('inTransitCount'), _list('inTransitGroups'), Colors.orange),
      ],
    );
  }

  Widget _groupCard(String title, int count, List<dynamic> rows, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(label: Text('$count cont'), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No data', style: TextStyle(color: Colors.grey)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 38,
                        dataRowMinHeight: 34,
                        dataRowMaxHeight: 40,
                        headingRowColor: WidgetStatePropertyAll(
                            color.withValues(alpha: 0.12)),
                        columns: const [
                          DataColumn(label: Text('DEPOT')),
                          DataColumn(label: Text('AGENT')),
                          DataColumn(label: Text('LINE')),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('TOTAL')),
                          DataColumn(label: Text('E')),
                          DataColumn(label: Text('F')),
                          DataColumn(label: Text('D')),
                          DataColumn(label: Text('Other')),
                        ],
                        rows: List.generate(rows.length, (i) {
                          final m = rows[i] as Map<String, dynamic>;
                          return DataRow(
                            color: i.isEven
                                ? const WidgetStatePropertyAll(Color(0xFFF7FAFC))
                                : null,
                            cells: [
                              DataCell(Text('${m['depot'] ?? ''}')),
                              DataCell(Text('${m['agent'] ?? ''}')),
                              DataCell(Text('${m['line'] ?? ''}')),
                              DataCell(Text('${m['containerType'] ?? ''}')),
                              DataCell(Text('${m['containerCount'] ?? 0}')),
                              DataCell(Text('${m['emptyCount'] ?? 0}')),
                              DataCell(Text('${m['fullCount'] ?? 0}')),
                              DataCell(Text('${m['damagedCount'] ?? 0}')),
                              DataCell(Text('${m['otherFelCount'] ?? 0}')),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    final records = _list('records');
    final total = records.length;
    final pageCount = total == 0 ? 1 : (total / _detailRowsPerPage).ceil();
    if (_detailPage >= pageCount) _detailPage = pageCount - 1;
    if (_detailPage < 0) _detailPage = 0;
    final start = _detailPage * _detailRowsPerPage;
    final end =
        (start + _detailRowsPerPage) > total ? total : start + _detailRowsPerPage;
    final pageRows = start < total ? records.sublist(start, end) : <dynamic>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_on, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'CONTAINER DETAIL  ·  ${_dashboard['filteredCount'] ?? 0} / ${_dashboard['totalRecords'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showDetailGrid = !_showDetailGrid),
                  icon: Icon(
                      _showDetailGrid ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  label: Text(_showDetailGrid ? 'Hide' : 'Show'),
                ),
              ],
            ),
            if (_showDetailGrid) ...[
              const Divider(height: 16),
              if (total == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No containers match the current filters.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else ...[
                SizedBox(
                  height: 420,
                  child: Scrollbar(
                    controller: _detailVCtrl,
                    thumbVisibility: true,
                    child: Scrollbar(
                      controller: _detailHCtrl,
                      thumbVisibility: true,
                      notificationPredicate: (n) => n.depth == 1,
                      child: SingleChildScrollView(
                        controller: _detailVCtrl,
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          controller: _detailHCtrl,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 36,
                            dataRowMaxHeight: 44,
                            headingRowColor: WidgetStatePropertyAll(
                                ThemeColors.getPrimaryColor(context)
                                    .withValues(alpha: 0.10)),
                            columns: const [
                              DataColumn(label: Text('DEPOT')),
                              DataColumn(label: Text('Container')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('IN/OUT')),
                              DataColumn(label: Text('Size')),
                              DataColumn(label: Text('F/E/D')),
                              DataColumn(label: Text('Seal')),
                            ],
                            rows: List.generate(pageRows.length, (i) {
                              final r = pageRows[i] as Map<String, dynamic>;
                              final container =
                                  '${r['itemNo'] ?? r['iteM_NO'] ?? r['ITEM_NO'] ?? ''}';
                              final containerKey =
                                  '${r['containerKey'] ?? container}';
                              final selected = _selectedContainer == containerKey;
                              return DataRow(
                                selected: selected,
                                color: selected
                                    ? WidgetStatePropertyAll(
                                        ThemeColors.getPrimaryColor(context)
                                            .withValues(alpha: 0.18))
                                    : (i.isEven
                                        ? const WidgetStatePropertyAll(
                                            Color(0xFFF7FAFC))
                                        : null),
                                onSelectChanged: (_) =>
                                    _selectContainer(containerKey),
                                cells: [
                                  DataCell(Text('${r['depotDisplay'] ?? ''}')),
                                  DataCell(Text(container)),
                                  DataCell(Text('${r['status'] ?? ''}')),
                                  DataCell(Text('${r['movementDisplay'] ?? ''}')),
                                  DataCell(Text('${r['sizeType'] ?? ''}')),
                                  DataCell(Text('${r['fel'] ?? ''}')),
                                  DataCell(Text('${r['soseal'] ?? ''}')),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPager(total, pageCount, start, end),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPager(int total, int pageCount, int start, int end) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rows:', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: _detailRowsPerPage,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: const [25, 50, 100, 200]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _detailRowsPerPage = v;
                  _detailPage = 0;
                });
              },
            ),
          ],
        ),
        Text(
          total == 0 ? '0' : '${start + 1}–$end of $total',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'First',
              visualDensity: VisualDensity.compact,
              onPressed:
                  _detailPage > 0 ? () => setState(() => _detailPage = 0) : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              tooltip: 'Previous',
              visualDensity: VisualDensity.compact,
              onPressed: _detailPage > 0
                  ? () => setState(() => _detailPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${_detailPage + 1} / $pageCount',
                style: const TextStyle(fontSize: 12)),
            IconButton(
              tooltip: 'Next',
              visualDensity: VisualDensity.compact,
              onPressed: _detailPage < pageCount - 1
                  ? () => setState(() => _detailPage++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Last',
              visualDensity: VisualDensity.compact,
              onPressed: _detailPage < pageCount - 1
                  ? () => setState(() => _detailPage = pageCount - 1)
                  : null,
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('EVENT HISTORY · $_selectedContainer',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _selectedContainer = null;
                    _selectedEvents = [];
                  }),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const Divider(height: 16),
            if (_selectedEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No events', style: TextStyle(color: Colors.grey)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 38,
                        dataRowMinHeight: 34,
                        dataRowMaxHeight: 40,
                        columns: const [
                          DataColumn(label: Text('Source')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Method')),
                          DataColumn(label: Text('Reason')),
                        ],
                        rows: List.generate(_selectedEvents.length, (i) {
                          final r = _selectedEvents[i] as Map<String, dynamic>;
                          return DataRow(
                            color: i.isEven
                                ? const WidgetStatePropertyAll(Color(0xFFF7FAFC))
                                : null,
                            cells: [
                              DataCell(Text('${r['sourceTable'] ?? ''}')),
                              DataCell(Text('${r['status'] ?? ''}')),
                              DataCell(Text('${r['eventMethod'] ?? ''}')),
                              DataCell(Text('${r['statusReason'] ?? ''}')),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
