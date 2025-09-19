import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/views/Auth/reset_password_with_code_screen.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  bool get _canSubmit {
    final code = _codeController.text.trim();
    return !_loading && code.length == 6;
  }

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onFieldChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _resendCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final url = Uri.parse('$apiBase/api/auth/forgot-password');
      final payload = {'Email': widget.email};

      debugPrint('[RESEND_CODE] POST $url');
      debugPrint('[RESEND_CODE] payload: $payload');

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[RESEND_CODE] status: ${resp.statusCode}');
      debugPrint('[RESEND_CODE] headers: ${resp.headers}');
      debugPrint('[RESEND_CODE] body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final message =
            data['message'] as String? ??
            'Mã xác thực mới đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư và thư mục spam.';

        setState(() {
          _successMessage = message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else if (resp.statusCode == 404) {
        setState(() {
          _error =
              'Email không tồn tại trong hệ thống. Vui lòng kiểm tra lại địa chỉ email.';
        });
      } else if (resp.statusCode == 429) {
        setState(() {
          _error = 'Quá nhiều yêu cầu. Vui lòng thử lại sau 5 phút.';
        });
      } else if (resp.statusCode == 500) {
        setState(() {
          _error = 'Lỗi server. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.';
        });
      } else {
        String? message;
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['message'] is String) {
            message = data['message'] as String;
          } else if (data is Map && data['error'] is String) {
            message = data['error'] as String;
          }
        } catch (_) {}

        setState(() {
          _error =
              message ?? 'Gửi lại mã xác thực thất bại (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _error = 'Mã xác thực phải có 6 số');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final url = Uri.parse('$apiBase/api/auth/verify-code');
      final payload = {'Email': widget.email, 'Code': code};

      debugPrint('[VERIFY_CODE] POST $url');
      debugPrint('[VERIFY_CODE] payload: $payload');

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[VERIFY_CODE] status: ${resp.statusCode}');
      debugPrint('[VERIFY_CODE] body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Mã xác thực hợp lệ';

        setState(() {
          _successMessage = message;
        });

        // Navigate to reset password screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ResetPasswordWithCodeScreen(email: widget.email, code: code),
            ),
          );
        }
      } else {
        String? message;
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['message'] is String) {
            message = data['message'] as String;
          }
        } catch (_) {}
        setState(() {
          _error = message ?? 'Mã xác thực không đúng (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() => _error = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return AuthShell(
      title: 'Verify Code',
      subtitle: 'Enter the 6-digit code sent to your email',
      form: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email display (read-only)
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              widget.email,
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Code input field
          Text('Verification Code', style: ThemeColors.getLabelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 24,
                letterSpacing: 8,
              ),
              prefixIcon: Icon(Icons.security, color: Color(0xFF999999)),
              counterText: '', // Hide character counter
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mã 6 số đã được gửi đến email của bạn',
            style: TextStyle(
              fontSize: 12,
              color:
                  _codeController.text.length != 6 &&
                      _codeController.text.isNotEmpty
                  ? ThemeColors.getErrorColor(context)
                  : ThemeColors.getHintColor(context),
            ),
            textAlign: TextAlign.center,
          ),

          // Success message
          if (_successMessage != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Text(
                _successMessage!,
                style: ThemeColors.getErrorStyle(
                  context,
                ).copyWith(color: const Color(0xFF2E7D32)),
              ),
            ),
          ],

          // Error message
          if (_error != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(_error!, style: ThemeColors.getErrorStyle(context)),
            ),
          ],

          SizedBox(height: isSmallScreen ? 24 : 32),

          // Verify Code button
          ElevatedButton(
            onPressed: _canSubmit ? _verifyCode : null,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('VERIFY CODE'),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

          // Resend code button
          TextButton(
            onPressed: _loading ? null : _resendCode,
            child: const Text('Resend Code'),
          ),

          // Back to Sign In link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: ThemeColors.getHintStyle(context),
              ),
              TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
