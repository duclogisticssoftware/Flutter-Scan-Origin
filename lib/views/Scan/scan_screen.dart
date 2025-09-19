import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/Scan/user_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qrscan_app/services/auth_service.dart';

// Use shared storage and apiBase from config

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _processing = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    setState(() => _processing = true);

    try {
      // Parse QR code as user ID
      final userId = int.tryParse(code);
      if (userId == null) {
        _showError('Invalid QR code format. Expected user ID.');
        return;
      }

      // Get current location
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showError(
              'Location permission denied. Please enable location access.',
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showError(
            'Location permissions are permanently denied. Please enable in settings.',
          );
          return;
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        _showError('Failed to get location: $e');
        return;
      }

      // Call API with location data
      final token = await AuthService.getToken();
      final requestBody = {
        'userId': userId,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      };

      final userResp = await http.post(
        Uri.parse('$apiBase/api/scan/scan-with-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (userResp.statusCode == 200) {
        final responseData = jsonDecode(userResp.body);
        _showUserDataWithLocation(responseData);
      } else if (userResp.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ
        await AuthService.logout();
        _showError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        // Navigate về login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else if (userResp.statusCode == 404) {
        _showError('User not found with ID: $userId');
      } else {
        _showError('Failed to get user data (${userResp.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showUserDataWithLocation(Map<String, dynamic> responseData) {
    // Dừng camera trước khi chuyển màn hình
    _controller?.stop();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              userData: responseData['scannedUser'],
              scanInfo: responseData['scanInfo'],
            ),
          ),
        )
        .then((_) {
          // Khởi động lại camera khi quay về màn hình scan
          _controller?.start();
        });
  }

  void _showError(String message) {
    // Dừng camera khi có lỗi
    _controller?.stop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Khởi động lại camera sau khi đóng dialog
              _controller?.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isMacOSDesktop = screenWidth > 1000 && screenHeight > 600;

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),

        // Processing overlay
        if (_processing)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeWidth: isSmallScreen ? 2 : 3,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Scan instructions
        Positioned(
          top: isSmallScreen ? 30 : 50,
          left: (isTablet || isMacOSDesktop) ? 40 : 20,
          right: (isTablet || isMacOSDesktop) ? 40 : 20,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Point camera at QR code to scan user ID',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Scan frame overlay for better UX
        if (!isVerySmallScreen)
          Center(
            child: Container(
              width: (isTablet || isMacOSDesktop) ? 300 : 250,
              height: (isTablet || isMacOSDesktop) ? 300 : 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF6B35), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  ...List.generate(4, (index) {
                    return Positioned(
                      top: index < 2 ? 0 : null,
                      bottom: index >= 2 ? 0 : null,
                      left: index % 2 == 0 ? 0 : null,
                      right: index % 2 == 1 ? 0 : null,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.only(
                            topLeft: index == 0
                                ? const Radius.circular(20)
                                : Radius.zero,
                            topRight: index == 1
                                ? const Radius.circular(20)
                                : Radius.zero,
                            bottomLeft: index == 2
                                ? const Radius.circular(20)
                                : Radius.zero,
                            bottomRight: index == 3
                                ? const Radius.circular(20)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Bottom instructions for very small screens
        if (isVerySmallScreen)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Align QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
