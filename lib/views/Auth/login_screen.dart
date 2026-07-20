import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrscan_app/views/Auth/register_screen.dart';
import 'package:qrscan_app/views/Auth/forgot_password_screen.dart';
import 'package:qrscan_app/views/shared/sidebar_navigation.dart';
import 'package:qrscan_app/views/shared/auth_shell.dart';
import 'package:qrscan_app/services/app_session.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _databaseName = TextEditingController();
  final TextEditingController _sqlUserId = TextEditingController();
  final TextEditingController _sqlPassword = TextEditingController();
  final TextEditingController _appUserName = TextEditingController();
  final TextEditingController _appPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _canSubmit {
    return !_loading &&
        _databaseName.text.trim().isNotEmpty &&
        _sqlUserId.text.trim().isNotEmpty &&
        _sqlPassword.text.isNotEmpty &&
        _appUserName.text.trim().isNotEmpty &&
        _appPassword.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _databaseName.addListener(_onFieldsChanged);
    _sqlUserId.addListener(_onFieldsChanged);
    _sqlPassword.addListener(_onFieldsChanged);
    _appUserName.addListener(_onFieldsChanged);
    _appPassword.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _databaseName.removeListener(_onFieldsChanged);
    _sqlUserId.removeListener(_onFieldsChanged);
    _sqlPassword.removeListener(_onFieldsChanged);
    _appUserName.removeListener(_onFieldsChanged);
    _appPassword.removeListener(_onFieldsChanged);
    _databaseName.dispose();
    _sqlUserId.dispose();
    _sqlPassword.dispose();
    _appUserName.dispose();
    _appPassword.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final databaseName = _databaseName.text.trim();
      final sqlUserId = _sqlUserId.text.trim();
      final sqlPassword = _sqlPassword.text;
      final appUserName = _appUserName.text.trim();
      final appPassword = _appPassword.text;

      await AuthService.loginTenant(
        databaseName: databaseName,
        sqlUserId: sqlUserId,
        sqlPassword: sqlPassword,
        appUserName: appUserName,
        appPassword: appPassword,
      );

      // Đồng bộ phiên NVOAMASIS — bắt buộc để có thông báo / duyệt phiếu
      final mobileError = await AppSession.connectMobileAndNotifications(
        databaseName: databaseName,
        sqlUserId: sqlUserId,
        sqlPassword: sqlPassword,
        appUserName: appUserName,
        appPassword: appPassword,
      );

      if (!mounted) return;

      if (mobileError != null) {
        setState(() {
          _error =
              'Scan OK nhưng NVOAMASIS thất bại:\n$mobileError\n\n'
              'Không vào được app khi thiếu phiên này. '
              'Kiểm tra databaseName / user giống web amasis.nvocc.vn rồi thử lại.';
          _loading = false;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SidebarNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openQrLogin() async {
    if (_loading) return;

    final qrToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrLoginScannerScreen()),
    );

    if (!mounted || qrToken == null || qrToken.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.loginByQr(qrToken);

      if (!mounted) return;

      // QR chỉ tạo phiên ScanApi — không có đủ credential cho NVOAMASIS.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cần đăng nhập đủ form'),
          content: const Text(
            'Đăng nhập QR chỉ vào được phần Scan.\n\n'
            'Thông báo duyệt phiếu cần login đủ 5 ô (giống web). '
            'Vui lòng đăng nhập bằng form.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _buildDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: ThemeColors.getHintStyle(context),
      prefixIcon: Icon(icon, color: ThemeColors.getHintColor(context)),
      filled: true,
      fillColor: ThemeColors.getCardColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.getBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.getBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.getPrimaryColor(context)),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(label, style: ThemeColors.getLabelStyle(context));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return AuthShell(
      title: 'Sign In',
      subtitle: 'Đăng nhập tenant hoặc quét QR để tiếp tục',
      form: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel(context, 'Database name'),
          const SizedBox(height: 8),
          TextField(
            controller: _databaseName,
            style: ThemeColors.getTextStyle(context),
            decoration: _buildDecoration(
              context,
              hintText: 'Nhập tên database tenant',
              icon: Icons.storage_outlined,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          _buildFieldLabel(context, 'SQL user ID'),
          const SizedBox(height: 8),
          TextField(
            controller: _sqlUserId,
            style: ThemeColors.getTextStyle(context),
            decoration: _buildDecoration(
              context,
              hintText: 'Nhập tài khoản SQL',
              icon: Icons.badge_outlined,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          _buildFieldLabel(context, 'SQL password'),
          TextField(
            controller: _sqlPassword,
            obscureText: true,
            style: ThemeColors.getTextStyle(context),
            decoration: _buildDecoration(
              context,
              hintText: 'Nhập mật khẩu SQL',
              icon: Icons.lock_outline,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          _buildFieldLabel(context, 'App user name'),
          const SizedBox(height: 8),
          TextField(
            controller: _appUserName,
            style: ThemeColors.getTextStyle(context),
            decoration: _buildDecoration(
              context,
              hintText: 'Nhập user ứng dụng',
              icon: Icons.person_outline,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel(context, 'App password'),
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
            controller: _appPassword,
            obscureText: true,
            style: ThemeColors.getTextStyle(context),
            decoration: _buildDecoration(
              context,
              hintText: 'Nhập mật khẩu ứng dụng',
              icon: Icons.password_outlined,
            ),
          ),

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

          SizedBox(height: isSmallScreen ? 16 : 20),

          OutlinedButton.icon(
            onPressed: _loading ? null : _openQrLogin,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('ĐĂNG NHẬP BẰNG QR'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: ThemeColors.getPrimaryColor(context)),
              foregroundColor: ThemeColors.getPrimaryColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

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
        ],
      ),
    );
  }
}

class _QrLoginScannerScreen extends StatefulWidget {
  const _QrLoginScannerScreen();

  @override
  State<_QrLoginScannerScreen> createState() => _QrLoginScannerScreenState();
}

class _QrLoginScannerScreenState extends State<_QrLoginScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _tokenController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitToken(String token) async {
    final trimmedToken = token.trim();
    if (_submitting || trimmedToken.isEmpty) {
      return;
    }

    _submitting = true;
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(trimmedToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập bằng QR')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final rawValue = capture.barcodes.firstOrNull?.rawValue;
                if (rawValue != null) {
                  _submitToken(rawValue);
                }
              },
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.no_photography_outlined,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không mở được camera. Vui lòng cấp quyền camera '
                          'hoặc dán token QR bên dưới.',
                          textAlign: TextAlign.center,
                          style: ThemeColors.getHintStyle(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quét mã QR đăng nhập hoặc dán token thủ công.',
                  style: ThemeColors.getHintStyle(context),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'QR token',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _submitToken(_tokenController.text),
                  child: const Text('SỬ DỤNG TOKEN NÀY'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
