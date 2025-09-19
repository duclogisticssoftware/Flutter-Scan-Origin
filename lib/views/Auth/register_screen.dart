import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _serverMessage;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onFieldChanged);
    _fullName.addListener(_onFieldChanged);
    _password.addListener(_onFieldChanged);
    _confirm.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _email.removeListener(_onFieldChanged);
    _fullName.removeListener(_onFieldChanged);
    _password.removeListener(_onFieldChanged);
    _confirm.removeListener(_onFieldChanged);
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Trigger rebuild for button enable/disable and error clearance on edits
    if (mounted) setState(() {});
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

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
    final email = _email.text.trim();
    final fullName = _fullName.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    return !_loading &&
        email.isNotEmpty &&
        fullName.isNotEmpty &&
        password.isNotEmpty &&
        confirm.isNotEmpty &&
        _isValidEmail(email) &&
        _isStrongPassword(password) &&
        password == confirm;
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final fullName = _fullName.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    // Validate email format
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }

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
      _serverMessage = null;
    });
    try {
      final url = Uri.parse('$apiBase/api/auth/register');
      final payload = {
        'Email': email,
        'PasswordHash': password, // Send as PasswordHash to match C# API
        'FullName': fullName, // Use user input FullName
      };

      debugPrint('[REGISTER] POST $url');
      debugPrint('[REGISTER] payload: ' + payload.toString());

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[REGISTER] status: ${resp.statusCode}');
      debugPrint('[REGISTER] body: ${resp.body}');

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
            ),
          );
          Navigator.of(context).pop(true);
        }
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
          _serverMessage = message;
          _error = 'Đăng ký thất bại (${resp.statusCode})';
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
      title: 'Sign Up',
      subtitle: 'Create your account to get started',
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

          // Full Name field
          Text('Full Name', style: ThemeColors.getLabelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _fullName,
            style: ThemeColors.getTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: ThemeColors.getHintStyle(context),
              prefixIcon: Icon(
                Icons.person_outline,
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
          Text('Password', style: ThemeColors.getLabelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            style: ThemeColors.getTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Create a strong password',
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
          const SizedBox(height: 4),
          Text(
            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
            style: ThemeColors.getHintStyle(context).copyWith(
              fontSize: 12,
              color:
                  _password.text.isNotEmpty &&
                      !_isStrongPassword(_password.text)
                  ? ThemeColors.getErrorColor(context)
                  : ThemeColors.getHintColor(context),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Confirm password field
          Text('Confirm Password', style: ThemeColors.getLabelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            obscureText: true,
            style: ThemeColors.getTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Confirm your password',
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
          const SizedBox(height: 4),
          Text(
            _confirm.text.isNotEmpty && _password.text != _confirm.text
                ? 'Mật khẩu không khớp'
                : '',
            style: ThemeColors.getErrorStyle(context).copyWith(fontSize: 12),
          ),

          // Error messages
          if (_serverMessage != null) ...[
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
              child: Text(
                _serverMessage!,
                style: ThemeColors.getErrorStyle(context),
              ),
            ),
          ],
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

          // Sign Up button
          ElevatedButton(
            onPressed: _canSubmit ? _register : null,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('SIGN UP', style: ThemeColors.getTextStyle(context)),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

          // Sign In link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: ThemeColors.getHintStyle(context),
              ),
              TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Sign In',
                  style: ThemeColors.getTextStyle(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
