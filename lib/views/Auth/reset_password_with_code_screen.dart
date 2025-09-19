import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class ResetPasswordWithCodeScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordWithCodeScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordWithCodeScreen> createState() =>
      _ResetPasswordWithCodeScreenState();
}

class _ResetPasswordWithCodeScreenState
    extends State<ResetPasswordWithCodeScreen> {
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
      final url = Uri.parse('$apiBase/api/auth/reset-password-with-code');
      final payload = {
        'Email': widget.email,
        'Code': widget.code,
        'NewPassword': password,
      };

      debugPrint('[RESET_PASSWORD_WITH_CODE] POST $url');
      debugPrint('[RESET_PASSWORD_WITH_CODE] payload: $payload');

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[RESET_PASSWORD_WITH_CODE] status: ${resp.statusCode}');
      debugPrint('[RESET_PASSWORD_WITH_CODE] body: ${resp.body}');

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
          Text('Email', style: ThemeColors.getLabelStyle(context)),
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
              style: ThemeColors.getCardSubtitleStyle(context),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // New password field
          Text('New Password', style: ThemeColors.getLabelStyle(context)),
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
          Text(
            'Confirm New Password',
            style: ThemeColors.getLabelStyle(context),
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
            style: ThemeColors.getErrorStyle(context).copyWith(fontSize: 12),
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
