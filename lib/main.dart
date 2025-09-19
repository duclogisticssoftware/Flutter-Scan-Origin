import 'package:flutter/material.dart';
import 'package:qrscan_app/views/shared/sidebar_navigation.dart';
import 'package:qrscan_app/views/Auth/login_screen.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/services/theme_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService.instance,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'QRScan App',
            theme: ThemeService.getLightTheme(),
            darkTheme: ThemeService.getDarkTheme(),
            themeMode: ThemeService.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Kiểm tra authentication status
      final isAuthenticated = await AuthService.isAuthenticated();

      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      // Có lỗi, cần login lại
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kiểm tra đăng nhập...'),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const SidebarNavigation() : const LoginScreen();
  }
}

// RootNav is now replaced by SidebarNavigation
