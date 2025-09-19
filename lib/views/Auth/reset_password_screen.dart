import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false; // Uppercase
    if (!RegExp(r'[a-z]').hasMatch(password)) return false; // Lowercase
    if (!RegExp(r'[0-9]').hasMatch(password)) return false; // Number
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password))
      return false; // Special char
    return true;
  }

  bool get _canSubmit {
    final password = _newPassword.text;
    final confirm = _confirmPassword.text;
    return !_loading &&
        password.isNotEmpty &&
        confirm.isNotEmpty &&
        _isStrongPassword(password) &&
        password == confirm;
  }

  @override
  void initState() {
    super.initState();
    _newPassword.addListener(_onFieldChanged);
    _confirmPassword.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _newPassword.removeListener(_onFieldChanged);
    _confirmPassword.removeListener(_onFieldChanged);
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _resetPassword() async {
    final password = _newPassword.text;
    final confirm = _confirmPassword.text;

    // Validate password strength
    if (!_isStrongPassword(password)) {
      setState(
        () => _error =
            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
      );
      return;
    }

    // Validate password match
    if (password != confirm) {
      setState(() => _error = 'Mật khẩu không khớp');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final url = Uri.parse('$apiBase/api/auth/reset-password-with-token');
      final payload = {
        'Email': widget.email,
        'Token': widget.token,
        'NewPassword': password,
      };

      debugPrint('[RESET_PASSWORD] POST $url');
      debugPrint('[RESET_PASSWORD] payload: $payload');

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[RESET_PASSWORD] status: ${resp.statusCode}');
      debugPrint('[RESET_PASSWORD] body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final message =
            data['message'] as String? ?? 'Đặt lại mật khẩu thành công';

        setState(() {
          _successMessage = message;
        });

        // Show success dialog and navigate back to login
        if (mounted) {
          _showSuccessDialog();
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
          _error = message ?? 'Đặt lại mật khẩu thất bại (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() => _error = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: const Text(
          'Mật khẩu đã được đặt lại thành công. Bạn có thể đăng nhập với mật khẩu mới.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return AuthShell(
      title: 'Reset Password',
      subtitle: 'Enter your new password',
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

          // New password field
          const Text(
            'New Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter new password',
              hintStyle: TextStyle(color: Color(0xFF999999)),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF999999)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
            style: TextStyle(
              fontSize: 12,
              color:
                  _newPassword.text.isNotEmpty &&
                      !_isStrongPassword(_newPassword.text)
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF666666),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Confirm password field
          const Text(
            'Confirm New Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Confirm new password',
              hintStyle: TextStyle(color: Color(0xFF999999)),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF999999)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _confirmPassword.text.isNotEmpty &&
                    _newPassword.text != _confirmPassword.text
                ? 'Mật khẩu không khớp'
                : '',
            style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
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
                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 14),
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
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14),
              ),
            ),
          ],

          SizedBox(height: isSmallScreen ? 24 : 32),

          // Reset Password button
          ElevatedButton(
            onPressed: _canSubmit ? _resetPassword : null,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('RESET PASSWORD'),
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
