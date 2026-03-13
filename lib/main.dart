import 'package:flutter/material.dart';
import 'package:qrscan_app/views/shared/sidebar_navigation.dart';
import 'package:qrscan_app/views/Auth/login_screen.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/services/theme_service.dart';
import 'package:qrscan_app/services/location_tracking_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ThemeService.init();

    // Khôi phục trạng thái tracking nếu có
    await LocationTrackingService().restoreTrackingState();
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      // App bị đóng hoàn toàn
      LocationTrackingService().onAppClose();
    }
  }

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
      debugPrint('[AUTH] Checking authentication...');
      // Kiểm tra authentication status
      final isAuthenticated = await AuthService.isAuthenticated();
      debugPrint('[AUTH] Authentication result: $isAuthenticated');

      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AUTH] Error checking authentication: $e');
      // Có lỗi, cần login lại
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
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
