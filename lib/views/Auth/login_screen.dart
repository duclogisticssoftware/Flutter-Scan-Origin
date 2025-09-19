import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/Auth/register_screen.dart';
import 'package:qrscan_app/views/Auth/forgot_password_screen.dart';
import 'package:qrscan_app/views/shared/sidebar_navigation.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool get _canSubmit {
    final email = _email.text.trim();
    return !_loading &&
        email.isNotEmpty &&
        _password.text.isNotEmpty &&
        _isValidEmail(email);
  }

  @override
  void initState() {
    super.initState();
    _email.addListener(_onFieldsChanged);
    _password.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _email.removeListener(_onFieldsChanged);
    _password.removeListener(_onFieldsChanged);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _login() async {
    final email = _email.text.trim();

    // Validate email format
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.parse('$apiBase/api/auth/login');
      final payload = {
        'Email': email,
        'PasswordHash': _password.text, // Send as PasswordHash to match C# API
      };
      debugPrint('[LOGIN] POST ' + url.toString());
      debugPrint('[LOGIN] payload: ' + payload.toString());
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[LOGIN] status: ${resp.statusCode}');
      debugPrint('[LOGIN] body: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token =
            (data['token'] ??
                    data['access_token'] ??
                    data['accessToken'] ??
                    data['jwt'])
                as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Token not found');
        }

        // Lưu token và thông tin login
        await AuthService.saveToken(token);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SidebarNavigation()),
            (route) => false,
          );
        }
      } else {
        String? message;
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['message'] is String)
            message = body['message'] as String;
          if (message == null && body is Map && body['error'] is String)
            message = body['error'] as String;
        } catch (_) {}
        _error = message ?? 'Đăng nhập thất bại (${resp.statusCode})';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return AuthShell(
      title: 'Sign In',
      subtitle: 'Better way to scan QR codes',
      form: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          Text('Email', style: ThemeColors.getLabelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: ThemeColors.getTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: ThemeColors.getHintStyle(context),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: ThemeColors.getHintColor(context),
              ),
              filled: true,
              fillColor: ThemeColors.getCardColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getPrimaryColor(context),
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Password field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Password', style: ThemeColors.getLabelStyle(context)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: ThemeColors.getHintStyle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            style: ThemeColors.getTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: ThemeColors.getHintStyle(context),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: ThemeColors.getHintColor(context),
              ),
              filled: true,
              fillColor: ThemeColors.getCardColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getPrimaryColor(context),
                ),
              ),
            ),
          ),

          // Error message
          if (_error != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.getErrorBackgroundColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.getErrorBorderColor(context),
                ),
              ),
              child: Text(_error!, style: ThemeColors.getErrorStyle(context)),
            ),
          ],

          SizedBox(height: isSmallScreen ? 24 : 32),

          // Sign In button
          ElevatedButton(
            onPressed: _canSubmit ? _login : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.getPrimaryColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('SIGN IN', style: ThemeColors.getTextStyle(context)),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

          // Sign Up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: ThemeColors.getHintStyle(context),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: ThemeColors.getPrimaryColor(context),
                ),
                child: Text(
                  'Sign Up',
                  style: ThemeColors.getTextStyle(context),
                ),
              ),
            ],
          ),

          // Only show social login on larger screens
          if (!isVerySmallScreen) ...[
            SizedBox(height: isSmallScreen ? 24 : 32),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(color: ThemeColors.getBorderColor(context)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or sign in with:',
                    style: ThemeColors.getHintStyle(
                      context,
                    ).copyWith(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Divider(color: ThemeColors.getBorderColor(context)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Social login buttons
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    onPressed: () {
                      // TODO: Implement Facebook login
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Google',
                    onPressed: () {
                      // TODO: Implement Google login
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: ThemeColors.getTextColor(context)),
      label: Text(label, style: ThemeColors.getTextStyle(context)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: ThemeColors.getBorderColor(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: ThemeColors.getCardColor(context),
      ),
    );
  }
}
