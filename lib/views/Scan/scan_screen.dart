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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Scan instructions
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Point camera at QR code to scan user ID',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
