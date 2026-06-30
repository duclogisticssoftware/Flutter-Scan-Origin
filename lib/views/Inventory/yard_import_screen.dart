import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qrscan_app/services/container_inventory_service.dart';
import 'package:qrscan_app/services/yard_import_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class YardImportScreen extends StatefulWidget {
  final String version;
  final String title;

  const YardImportScreen({
    super.key,
    required this.version,
    required this.title,
  });

  @override
  State<YardImportScreen> createState() => _YardImportScreenState();
}

class _YardImportScreenState extends State<YardImportScreen> {
  bool _loading = false;
  String? _depot;
  List<String> _depots = [];
  Map<String, dynamic>? _preview;
  ({Uint8List bytes, String name})? _file;

  bool get _needsDepot => widget.version != '837';

  @override
  void initState() {
    super.initState();
    _loadDepots();
  }

  Future<void> _loadDepots() async {
    final depots = await ContainerInventoryService.getDepots();
    if (mounted) setState(() => _depots = depots);
  }

  Future<void> _pickFile() async {
    final picked = await YardImportService.pickExcelFile();
    if (picked == null) return;
    setState(() {
      _file = picked;
      _preview = null;
    });
    await _previewFile();
  }

  Future<void> _previewFile() async {
    if (_file == null) return;
    if (_needsDepot && (_depot == null || _depot!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn depot trước khi preview.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _callPreview();
      if (mounted) setState(() => _preview = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importFile() async {
    if (_file == null) return;
    if (_needsDepot && (_depot == null || _depot!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn depot trước khi import.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _callImport();
      if (mounted) {
        final msg = result['message']?.toString() ??
            'Import xong (${result['inserted'] ?? 0} dòng)';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _callPreview() {
    final f = _file!;
    final depot = _depot ?? 'SP-ITC';
    switch (widget.version) {
      case '834':
        return YardImportService.preview834(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '835':
        return YardImportService.preview835(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '836':
        return YardImportService.preview836(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '837':
        return YardImportService.preview837(
            fileBytes: f.bytes, fileName: f.name);
      default:
        throw Exception('Version không hợp lệ');
    }
  }

  Future<Map<String, dynamic>> _callImport() {
    final f = _file!;
    final depot = _depot ?? 'SP-ITC';
    switch (widget.version) {
      case '834':
        return YardImportService.import834(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '835':
        return YardImportService.import835(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '836':
        return YardImportService.import836(
            fileBytes: f.bytes, fileName: f.name, depot: depot);
      case '837':
        return YardImportService.import837(
            fileBytes: f.bytes, fileName: f.name);
      default:
        throw Exception('Version không hợp lệ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_needsDepot)
              DropdownButtonFormField<String>(
                initialValue:
                    _depot != null && _depots.contains(_depot) ? _depot : null,
                decoration: const InputDecoration(
                  labelText: 'Depot name',
                  border: OutlineInputBorder(),
                ),
                items: _depots
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _depot = v),
              ),
            if (_needsDepot) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_file == null ? 'Chọn file Excel' : _file!.name),
            ),
            const SizedBox(height: 12),
            if (_preview != null) Expanded(child: _buildPreviewPanel()),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading || _file == null ? null : _importFile,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
              label: const Text('IMPORT DB'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final p = _preview!;
    final sheets = (p['sheets'] as List<dynamic>?) ?? [];
    final total = p['totalRows'] ?? 0;
    final importable = p['importableRows'] ?? 0;
    final existing = p['existingRows'] ?? 0;
    final dup = p['batchDuplicateRows'] ?? 0;
    final invalid = p['invalidRows'] ?? 0;
    final message = p['message']?.toString() ?? '';

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip('Total', total, Colors.blueGrey),
                    _chip('New', importable, Colors.green),
                    _chip('Existing DB', existing, Colors.orange),
                    _chip('File dup', dup, Colors.amber),
                    _chip('Errors', invalid, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DefaultTabController(
              length: sheets.isEmpty ? 1 : sheets.length,
              child: Column(
                children: [
                  if (sheets.isNotEmpty)
                    TabBar(
                      isScrollable: true,
                      tabs: sheets
                          .map((s) => Tab(
                                text:
                                    '${s['sheetName']} (${s['totalRows'] ?? 0})',
                              ))
                          .toList(),
                    ),
                  Expanded(
                    child: sheets.isEmpty
                        ? const Center(child: Text('Không có sheet hợp lệ.'))
                        : TabBarView(
                            children: sheets
                                .map<Widget>((s) => _buildSheetTable(s))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, dynamic value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }

  Widget _buildSheetTable(Map<String, dynamic> sheet) {
    final rows = (sheet['rows'] as List<dynamic>?) ?? [];
    if (rows.isEmpty) {
      return const Center(child: Text('Không có dòng preview.'));
    }

    final keys = <String>{};
    for (final row in rows) {
      final values = row['values'] as Map<String, dynamic>? ?? {};
      keys.addAll(values.keys.map((e) => e.toString()));
    }
    final columns = keys.take(8).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('Status')),
            ...columns.map((c) => DataColumn(label: Text(c))),
          ],
          rows: rows.take(100).map<DataRow>((row) {
            final values = row['values'] as Map<String, dynamic>? ?? {};
            final status = row['isExisting'] == true
                ? 'DB'
                : row['isBatchDuplicate'] == true
                    ? 'DUP'
                    : row['canImport'] == true
                        ? 'NEW'
                        : 'ERR';
            return DataRow(
              cells: [
                DataCell(Text('${row['excelRowNumber'] ?? ''}')),
                DataCell(Text(status)),
                ...columns.map((c) => DataCell(Text(values[c]?.toString() ?? ''))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
