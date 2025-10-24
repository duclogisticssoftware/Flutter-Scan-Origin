import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/views/Scan/user_detail_screen.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/services/location_tracking_service.dart';

// Use shared storage and apiBase from config

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _processing = false;
  MobileScannerController? _controller;
  final TextEditingController _hblController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hblController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    setState(() => _processing = true);

    try {
      // Parse QR code as HBL number
      final hblNo = code.trim();
      if (hblNo.isEmpty) {
        _showError('Invalid QR code format. Expected HBL number.');
        return;
      }

      // Get current location
      String? latitude;
      String? longitude;

      try {
        // Kiểm tra GPS có bật không
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('[FLUTTER] Location services are disabled');
        } else {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 10),
            forceAndroidLocationManager: false, // Sử dụng FusedLocationProvider
          );

          // Kiểm tra độ chính xác
          if (position.accuracy <= 50) {
            // Chỉ sử dụng nếu sai số <= 50m
            latitude = position.latitude.toString();
            longitude = position.longitude.toString();
            print(
              '[FLUTTER] Current location: $latitude, $longitude (accuracy: ${position.accuracy}m)',
            );
          } else {
            print(
              '[FLUTTER] Location accuracy too low: ${position.accuracy}m, using without location',
            );
          }
        }
      } catch (e) {
        print('[FLUTTER] Failed to get location: $e');
        // Vẫn tiếp tục gửi API mà không có vị trí
      }

      // Call HBL scan API - gửi object theo format ScanHBLRequest
      final token = await AuthService.getToken();

      // Tạo request body theo format ScanHBLRequest
      final requestBody = {
        'HBLNo': hblNo,
        'Latitude': latitude,
        'Longitude': longitude,
      };

      print('[FLUTTER] Sending request to: $apiBase/api/scan/scan-hbl');
      print('[FLUTTER] Request body: $requestBody');

      final hblResp = await http.post(
        Uri.parse('$apiBase/api/scan/scan-hbl'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('[FLUTTER] Response status: ${hblResp.statusCode}');
      print('[FLUTTER] Response body: ${hblResp.body}');

      if (hblResp.statusCode == 200) {
        final responseData = jsonDecode(hblResp.body);
        _showHBLDataWithLocation(responseData);
      } else if (hblResp.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ
        await AuthService.logout();
        _showError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        // Navigate về login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else if (hblResp.statusCode == 404) {
        final errorData = jsonDecode(hblResp.body);
        _showError('${errorData['message']}: ${errorData['hblNo']}');
      } else if (hblResp.statusCode == 400) {
        final errorData = jsonDecode(hblResp.body);
        _showError('${errorData['message']}: ${errorData['hblNo']}');
      } else {
        _showError('Failed to scan HBL (${hblResp.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showHBLDataWithLocation(Map<String, dynamic> responseData) async {
    // Dừng camera trước khi chuyển màn hình
    _controller?.stop();

    // Bắt đầu tracking vị trí cho HBL
    final hblNo = responseData['hblInfo']?['hblNo'];
    if (hblNo != null) {
      final trackingStarted = await LocationTrackingService().startTracking(
        hblNo,
      );
      if (trackingStarted) {
        _showTrackingStartedDialog(hblNo);
      }
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              hblData: responseData,
              scanInfo: responseData['scanInfo'],
            ),
          ),
        )
        .then((_) {
          // Khởi động lại camera khi quay về màn hình scan
          _controller?.start();
        });
  }

  void _showTrackingStartedDialog(String hblNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Location Tracking Started'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HBL: $hblNo'),
            const SizedBox(height: 8),
            const Text(
              'Location tracking is now active. Your position will be sent to the server every 60 minutes.',
            ),
            const SizedBox(height: 8),
            const Text(
              'You can minimize the app and tracking will continue in the background.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Future<void> _scanHBLManually(String hblNo) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      // Debug logging
      print('[FLUTTER] ===== START MANUAL INPUT HBL =====');
      print('[FLUTTER] HBL Number: $hblNo');
      print('[FLUTTER] API Base: $apiBase');

      // Call HBL input API - chỉ gửi HBL number
      final token = await AuthService.getToken();
      print('[FLUTTER] Token obtained: ${token != null ? "YES" : "NO"}');
      print('[FLUTTER] Token length: ${token?.length ?? 0}');

      // Lấy vị trí hiện tại trước khi gửi API
      String? latitude;
      String? longitude;

      try {
        // Kiểm tra GPS có bật không
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('[FLUTTER] Location services are disabled');
        } else {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 15),
            forceAndroidLocationManager: false, // Sử dụng FusedLocationProvider
          );

          // Kiểm tra độ chính xác
          if (position.accuracy <= 50) {
            // Chỉ sử dụng nếu sai số <= 50m
            latitude = position.latitude.toString();
            longitude = position.longitude.toString();
            print(
              '[FLUTTER] Current location: $latitude, $longitude (accuracy: ${position.accuracy}m)',
            );
          } else {
            print(
              '[FLUTTER] Location accuracy too low: ${position.accuracy}m, using without location',
            );
          }
        }
      } catch (e) {
        print('[FLUTTER] Failed to get location: $e');
        // Vẫn tiếp tục gửi API mà không có vị trí
      }

      // API expect InputHBLRequest object
      final requestBody = {
        'HBLNo': hblNo,
        'Latitude': latitude,
        'Longitude': longitude,
        'Ngay': DateTime.now().toIso8601String(),
      };

      print('[FLUTTER] Sending request to: $apiBase/api/scan/input-hbl');
      print('[FLUTTER] Request body (JSON object): $requestBody');

      final hblResp = await http.post(
        Uri.parse('$apiBase/api/scan/input-hbl'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody), // Send JSON object
      );

      print('[FLUTTER] Response status: ${hblResp.statusCode}');
      print('[FLUTTER] Response body: ${hblResp.body}');

      if (hblResp.statusCode == 200) {
        print('[FLUTTER] ✅ SUCCESS: HBL input successful');
        final responseData = jsonDecode(hblResp.body);
        print('[FLUTTER] Response data: $responseData');
        _showHBLDataWithLocation(responseData);
      } else if (hblResp.statusCode == 401) {
        print('[FLUTTER] ❌ ERROR: Unauthorized (401)');
        // Token hết hạn hoặc không hợp lệ
        await AuthService.logout();
        _showError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        // Navigate về login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else if (hblResp.statusCode == 404) {
        print('[FLUTTER] ❌ ERROR: HBL not found (404)');
        final errorData = jsonDecode(hblResp.body);
        print('[FLUTTER] Error data: $errorData');
        _showError('${errorData['message']}: ${errorData['hblNo']}');
      } else if (hblResp.statusCode == 400) {
        print('[FLUTTER] ❌ ERROR: Bad request (400)');
        final errorData = jsonDecode(hblResp.body);
        print('[FLUTTER] Error data: $errorData');
        _showError('${errorData['message']}: ${errorData['hblNo']}');
      } else {
        print('[FLUTTER] ❌ ERROR: Unknown status code ${hblResp.statusCode}');
        _showError('Failed to input HBL (${hblResp.statusCode})');
      }
    } catch (e) {
      print('[FLUTTER] ❌ EXCEPTION: $e');
      _showError('Error: $e');
    } finally {
      print('[FLUTTER] ===== END MANUAL INPUT HBL =====');
      setState(() => _processing = false);
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập HBL Number'),
        content: TextField(
          controller: _hblController,
          decoration: const InputDecoration(
            hintText: 'Nhập HBL number...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final hblNo = _hblController.text.trim();
              print('[FLUTTER] User input HBL: "$hblNo"');
              if (hblNo.isNotEmpty) {
                print('[FLUTTER] HBL is valid, proceeding with scan...');
                Navigator.of(context).pop();
                _scanHBLManually(hblNo);
              } else {
                print('[FLUTTER] HBL is empty, not proceeding');
              }
            },
            child: const Text('Quét'),
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
        MobileScanner(controller: _controller, onDetect: _onDetect),

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Point camera at QR code to scan HBL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                ElevatedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard, size: 18),
                  label: const Text('Nhập HBL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                  ),
                ),
              ],
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
                'Align HBL QR code within the frame',
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
