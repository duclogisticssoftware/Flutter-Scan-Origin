import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/views/Auth/verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool get _canSubmit {
    final email = _email.text.trim();
    return !_loading && email.isNotEmpty && _isValidEmail(email);
  }

  @override
  void initState() {
    super.initState();
    _email.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _email.removeListener(_onFieldChanged);
    _email.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _sendResetEmail() async {
    final email = _email.text.trim();

    // Validate email format
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final url = Uri.parse('$apiBase/api/auth/forgot-password');
      final payload = {'Email': email};

      debugPrint('[FORGOT_PASSWORD] POST $url');
      debugPrint('[FORGOT_PASSWORD] payload: $payload');

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[FORGOT_PASSWORD] status: ${resp.statusCode}');
      debugPrint('[FORGOT_PASSWORD] headers: ${resp.headers}');
      debugPrint('[FORGOT_PASSWORD] body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final message =
            data['message'] as String? ??
            'Mã xác thực đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư và thư mục spam.';

        setState(() {
          _successMessage = message;
        });

        // Navigate to verify code screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
          );
        }
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
              message ??
              'Gửi email reset thất bại (${resp.statusCode}). Vui lòng thử lại.';
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
      title: 'Forgot Password',
      subtitle: 'Enter your email to receive reset instructions',
      form: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(color: Color(0xFF999999)),
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF999999)),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Success message
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 14),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],

          // Error message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],

          // Send Reset Email button
          ElevatedButton(
            onPressed: _canSubmit ? _sendResetEmail : null,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('SEND RESET EMAIL'),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

          // Back to Sign In link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remember your password? ',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
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
