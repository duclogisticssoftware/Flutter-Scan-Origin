import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:qrscan_app/models/phieu_approve_detail.dart';
import 'package:qrscan_app/services/phieu_approve_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:qrscan_app/utils/vn_datetime.dart';

class PhieuApprovePage extends StatefulWidget {
  final String phieuToken;

  const PhieuApprovePage({super.key, required this.phieuToken});

  @override
  State<PhieuApprovePage> createState() => _PhieuApprovePageState();
}

class _PhieuApprovePageState extends State<PhieuApprovePage> {
  final _remarksController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PhieuApproveDetail? _detail;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await PhieuApproveService.getDetail(widget.phieuToken);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        if (detail.remarks != null && detail.remarks!.isNotEmpty) {
          _remarksController.text = detail.remarks!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showMessage(String message, {bool isError = false}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isError ? 'Không duyệt được' : 'Thành công'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(bool approve) async {
    final detail = _detail;
    if (detail == null || _submitting) return;

    if (!detail.showActionButtons) {
      await _showMessage(
        detail.alreadyDecided
            ? 'Phiếu đã được quyết định, không duyệt thêm được.'
            : 'Bạn không có quyền duyệt phiếu này.',
        isError: true,
      );
      return;
    }

    if (!approve) {
      final remarks = _remarksController.text.trim();
      if (remarks.isEmpty) {
        await _showMessage('Deny bắt buộc nhập lý do (remarks).', isError: true);
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Xác nhận Approve' : 'Xác nhận Deny'),
        content: Text(
          approve
              ? 'Bạn chắc chắn Approve phiếu này?'
              : 'Bạn chắc chắn Deny phiếu này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await PhieuApproveService.decide(
        phieuToken: widget.phieuToken,
        approve: approve,
        remarks: approve ? null : _remarksController.text.trim(),
      );
      if (!mounted) return;
      await _showMessage(
        result.message.isNotEmpty
            ? result.message
            : (approve ? 'Đã Approve.' : 'Đã Deny.'),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      await _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final title = detail == null
        ? 'Duyệt phiếu'
        : 'Duyệt ${detail.loaiLabel}${detail.soPhieu != null ? ' · ${detail.soPhieu}' : ''}';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading || _submitting ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[700],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Token: ${widget.phieuToken}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : detail == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _StatusBanner(detail: detail),
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: detail.detailHtml.trim().isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            'Không có chi tiết phiếu',
                                            style:
                                                ThemeColors.getCardSubtitleStyle(
                                              context,
                                            ),
                                          ),
                                        )
                                      : Html(data: detail.detailHtml),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ghi chú / Lý do Deny',
                                style: ThemeColors.getCardTitleStyle(context),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _remarksController,
                                maxLines: 3,
                                enabled:
                                    !_submitting && detail.showActionButtons,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Bắt buộc khi Deny (vd: Sai số tiền)',
                                ),
                              ),
                              if (detail.alreadyDecided &&
                                  (detail.remarks?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Remarks: ${detail.remarks}',
                                  style: ThemeColors.getCardSubtitleStyle(
                                    context,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: detail.showActionButtons
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _submitting
                                              ? null
                                              : () => _decide(false),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text('Deny'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _submitting
                                              ? null
                                              : () => _decide(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: _submitting
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    detail.alreadyDecided
                                        ? 'Phiếu đã quyết định — không còn nút Approve/Deny.'
                                        : 'Không có quyền duyệt phiếu này.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PhieuApproveDetail detail;

  const _StatusBanner({required this.detail});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    if (detail.alreadyDecided) {
      bg = detail.approve == true
          ? Colors.green.withOpacity(0.15)
          : Colors.red.withOpacity(0.15);
      fg = detail.approve == true ? Colors.green[800]! : Colors.red[800]!;
      text = detail.statusLabel;
      if (detail.approveBy != null && detail.approveBy!.isNotEmpty) {
        text = '$text bởi ${detail.approveBy}';
      }
      if (detail.approveDate != null) {
        text = '$text · ${VnDateTime.format(detail.approveDate)}';
      }
    } else if (!detail.canDecide) {
      bg = Colors.orange.withOpacity(0.15);
      fg = Colors.orange[900]!;
      text = 'Bạn không có quyền duyệt phiếu này';
    } else {
      bg = Colors.blue.withOpacity(0.12);
      fg = Colors.blue[900]!;
      text = 'Chờ bạn Approve / Deny';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
