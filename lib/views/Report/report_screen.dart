import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/services/http_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<String> _loaiList = [];
  bool _loadingLoai = true;
  String? _loaiError;

  String? _selectedLoai;
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _mblController = TextEditingController();
  final TextEditingController _hblController = TextEditingController();

  bool _loadingReport = false;
  String? _reportError;
  Map<String, dynamic>? _reportResult;

  @override
  void initState() {
    super.initState();
    _loadDistinctLoai();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  @override
  void dispose() {
    _mblController.dispose();
    _hblController.dispose();
    super.dispose();
  }

  Future<void> _loadDistinctLoai() async {
    setState(() {
      _loadingLoai = true;
      _loaiError = null;
    });

    try {
      final response = await HttpService.get(
        '$apiBase/api/JobProfitReport/loai',
      );

      if (!mounted) return;

      if (HttpService.isSuccess(response)) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          final list = data
              .map((e) => e is String ? e : e.toString())
              .whereType<String>()
              .toList();
          setState(() {
            _loaiList = list;
            _loadingLoai = false;
            if (list.isNotEmpty && _selectedLoai == null) {
              _selectedLoai = list.first;
            }
          });
        } else {
          setState(() {
            _loaiList = [];
            _loadingLoai = false;
            _loaiError = 'Định dạng dữ liệu loại không hợp lệ.';
          });
        }
      } else {
        setState(() {
          _loaiError = HttpService.getErrorMessage(response);
          _loadingLoai = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaiError = 'Lỗi: $e';
          _loadingLoai = false;
        });
      }
    }
  }

  Future<void> _runReport() async {
    if (_selectedLoai == null || _selectedLoai!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại (Loại job).')),
      );
      return;
    }
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khoảng thời gian From và To.'),
        ),
      );
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày To phải sau hoặc bằng ngày From.')),
      );
      return;
    }

    setState(() {
      _loadingReport = true;
      _reportError = null;
      _reportResult = null;
    });

    try {
      final fromStr = _formatDate(_fromDate!);
      final toStr = _formatDate(_toDate!);
      final queryParams = <String, String>{
        'from': fromStr,
        'to': toStr,
        'loai': _selectedLoai!,
      };
      final mbl = _mblController.text.trim();
      final hbl = _hblController.text.trim();
      if (mbl.isNotEmpty) queryParams['mbl'] = mbl;
      if (hbl.isNotEmpty) queryParams['hbl'] = hbl;

      final uri = Uri.parse(
        '$apiBase/api/JobProfitReport',
      ).replace(queryParameters: queryParams);

      final response = await HttpService.get(uri.toString());

      if (!mounted) return;

      if (HttpService.isSuccess(response)) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _reportResult = body;
          _loadingReport = false;
        });
      } else {
        String message = HttpService.getErrorMessage(response);
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['message'] != null) message = body['message'] as String;
        } catch (_) {}
        setState(() {
          _reportError = message;
          _loadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportError = 'Lỗi: $e';
          _loadingReport = false;
        });
      }
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo lợi nhuận theo HBL'),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Form lọc
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ lọc',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Loại (bắt buộc)
                  if (_loadingLoai)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Đang tải danh sách loại...'),
                        ],
                      ),
                    )
                  else if (_loaiError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loaiError!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadDistinctLoai,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedLoai,
                      decoration: const InputDecoration(
                        labelText: 'Loại (bắt buộc)',
                        border: OutlineInputBorder(),
                      ),
                      items: _loaiList
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLoai = v),
                    ),
                  if (!_loadingLoai && _loaiError == null)
                    const SizedBox(height: 16),
                  // Khoảng thời gian
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickFromDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Từ ngày',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _fromDate != null
                                  ? _formatDate(_fromDate!)
                                  : 'Chọn ngày',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _pickToDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Đến ngày',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _toDate != null
                                  ? _formatDate(_toDate!)
                                  : 'Chọn ngày',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // MBL, HBL (không bắt buộc)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mblController,
                          decoration: const InputDecoration(
                            labelText: 'Số MBL (tùy chọn)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _hblController,
                          decoration: const InputDecoration(
                            labelText: 'Số HBL (tùy chọn)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loadingReport ? null : _runReport,
                      icon: _loadingReport
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.assessment),
                      label: Text(
                        _loadingReport ? 'Đang tải...' : 'Xem báo cáo',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ThemeColors.getPrimaryColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Kết quả
          Expanded(child: _buildReportResult()),
        ],
      ),
    );
  }

  Widget _buildReportResult() {
    if (_loadingReport) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải báo cáo...'),
          ],
        ),
      );
    }

    if (_reportError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
              const SizedBox(height: 16),
              Text(
                _reportError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _runReport, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_reportResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chọn bộ lọc và nhấn "Xem báo cáo"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final data = _reportResult!['data'] as List<dynamic>? ?? [];
    final totalDebit =
        (_reportResult!['totalDebit'] as num?)?.toDouble() ?? 0.0;
    final totalCredit =
        (_reportResult!['totalCredit'] as num?)?.toDouble() ?? 0.0;
    final totalProfit =
        (_reportResult!['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final count = _reportResult!['count'] as int? ?? 0;
    const String currencyLabel = 'VND';

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có dữ liệu theo bộ lọc.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tổng quan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: ThemeColors.getPrimaryColor(context).withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryChip(
                    'Tổng Debit ($currencyLabel)',
                    totalDebit,
                    Colors.blue,
                  ),
                  _buildSummaryChip(
                    'Tổng Credit ($currencyLabel)',
                    totalCredit,
                    Colors.orange,
                  ),
                  _buildSummaryChip(
                    'Lợi nhuận ($currencyLabel)',
                    totalProfit,
                    totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildSummaryChip('Số HBL', count.toDouble(), Colors.purple),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Bảng dữ liệu
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    ThemeColors.getPrimaryColor(context).withOpacity(0.12),
                  ),
                  columns: const [
                    DataColumn(label: Text('Job No')),
                    DataColumn(label: Text('HBL')),
                    DataColumn(label: Text('MBL')),
                    DataColumn(label: Text('Date Report')),
                    DataColumn(
                      label: Text(
                        'Tổng Debit (VND)',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tổng Credit (VND)',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                  rows: data.map<DataRow>((e) {
                    final map = e as Map<String, dynamic>;
                    final jobNo = map['jobNo']?.toString() ?? '';
                    final hbl = map['hbl']?.toString() ?? '';
                    final mbl = map['mbl']?.toString() ?? '';
                    final dateReport = map['dateReport'];
                    final dateStr = _formatDateReport(dateReport);
                    final totalDebitRow =
                        (map['totalDebit'] as num?)?.toDouble() ?? 0.0;
                    final totalCreditRow =
                        (map['totalCredit'] as num?)?.toDouble() ?? 0.0;
                    return DataRow(
                      cells: [
                        DataCell(Text(jobNo)),
                        DataCell(Text(hbl)),
                        DataCell(Text(mbl)),
                        DataCell(Text(dateStr)),
                        DataCell(
                          Text('${_formatMoney(totalDebitRow)} $currencyLabel'),
                        ),
                        DataCell(
                          Text(
                            '${_formatMoney(totalCreditRow)} $currencyLabel',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String label, double value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(
          label == 'Số HBL' ? value.toInt().toString() : _formatMoney(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDateReport(dynamic dateReport) {
    if (dateReport == null) return '';
    if (dateReport is String) {
      try {
        final d = DateTime.parse(dateReport);
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {
        return dateReport;
      }
    }
    return '';
  }
}
