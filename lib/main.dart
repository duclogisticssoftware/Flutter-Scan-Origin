import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/navigation/app_navigator.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/services/background_notification_service.dart';
import 'package:qrscan_app/services/app_session.dart';
import 'package:qrscan_app/services/location_tracking_service.dart';
import 'package:qrscan_app/services/mobile_auth_service.dart';
import 'package:qrscan_app/services/notification_inbox_controller.dart';
import 'package:qrscan_app/services/push_notification_service.dart';
import 'package:qrscan_app/services/theme_service.dart';
import 'package:qrscan_app/views/Auth/login_screen.dart';
import 'package:qrscan_app/views/shared/sidebar_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ThemeService.init();
    await PushNotificationService.instance.init();
    await BackgroundNotificationService.init();
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

    if (state == AppLifecycleState.resumed) {
      AppSession.restoreNotificationsIfLoggedIn();
    } else if (state == AppLifecycleState.paused) {
      // App vào nền: sync một lần để hiện local notification sớm hơn WorkManager
      BackgroundNotificationService.syncOnce();
    } else if (state == AppLifecycleState.detached) {
      LocationTrackingService().onAppClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService.instance),
        ChangeNotifierProvider(create: (_) => NotificationInboxController()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'LMS APP',
            navigatorKey: AppNavigator.key,
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
      final scanOk = await AuthService.isAuthenticated();
      final mobileToken = await MobileAuthService.getAccessToken();
      final mobileOk = mobileToken != null && mobileToken.isNotEmpty;
      // Cần cả Scan + NVOAMASIS — thiếu mobile JWT thì bắt login lại
      // (tránh vào app từ phiên Scan cũ rồi Thông báo trống).
      final isAuthenticated = scanOk && mobileOk;
      debugPrint(
        '[AUTH] scan=$scanOk mobile=$mobileOk → authenticated=$isAuthenticated',
      );

      if (isAuthenticated) {
        await AppSession.restoreNotificationsIfLoggedIn();
      }

      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AUTH] Error checking authentication: $e');
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
