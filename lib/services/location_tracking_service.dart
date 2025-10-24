import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  Timer? _locationTimer;
  bool _isTracking = false;
  String? _currentHBL;

  bool get isTracking => _isTracking;
  String? get currentHBL => _currentHBL;

  // Bắt đầu tracking vị trí cho HBL
  Future<bool> startTracking(String hblNo) async {
    if (_isTracking) {
      return false; // Đã đang tracking
    }

    try {
      // Kiểm tra quyền location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      _currentHBL = hblNo;
      _isTracking = true;

      // Lưu trạng thái tracking
      await _saveTrackingState(true, hblNo);

      // Notify state changed
      _notifyStateChanged();

      // Bắt đầu timer để gửi vị trí mỗi 15 phút
      _locationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        _getCurrentLocationAndSend();
      });

      // Gửi vị trí ngay lập tức khi bắt đầu tracking
      _getCurrentLocationAndSend();

      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  // Dừng tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    // Gửi end location trước khi dừng tracking
    await _sendEndLocation();

    _isTracking = false;
    _currentHBL = null;

    // Dừng timer
    _locationTimer?.cancel();
    _locationTimer = null;

    // Lưu trạng thái tracking
    await _saveTrackingState(false, null);

    // Notify state changed
    _notifyStateChanged();

    debugPrint('Location tracking stopped');
  }

  // Lấy vị trí hiện tại và gửi lên server
  Future<void> _getCurrentLocationAndSend() async {
    if (!_isTracking || _currentHBL == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
        'Getting location for HBL: $_currentHBL - ${position.latitude}, ${position.longitude}',
      );

      // Gửi vị trí lên server
      await _sendLocationToServer(position);
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  // Gửi vị trí đến server
  Future<void> _sendLocationToServer(Position position) async {
    if (_currentHBL == null) return;

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final requestBody = {
        'HBLNo': _currentHBL, // Sử dụng HBLNo (string) thay vì HBLID (Guid)
        'Latitude': position.latitude.toString(),
        'Longitude': position.longitude.toString(),
        'Timestamp': DateTime.now().toIso8601String(),
        'Accuracy': position.accuracy,
        'Altitude': position.altitude,
        'Speed': position.speed,
        'Heading': position.heading,
      };

      final response = await http.post(
        Uri.parse('$apiBase/api/scan/save-hbl-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('Location sent successfully for HBL: $_currentHBL');
      } else {
        debugPrint('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending location: $e');
    }
  }

  // Lưu trạng thái tracking vào SharedPreferences
  Future<void> _saveTrackingState(bool isTracking, String? hblNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_tracking', isTracking);
      if (hblNo != null) {
        await prefs.setString('tracking_hbl', hblNo);
      } else {
        await prefs.remove('tracking_hbl');
      }
    } catch (e) {
      debugPrint('Error saving tracking state: $e');
    }
  }

  // Khôi phục trạng thái tracking khi khởi động app
  Future<void> restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isTracking = prefs.getBool('is_tracking') ?? false;
      final hblNo = prefs.getString('tracking_hbl');

      if (isTracking && hblNo != null) {
        debugPrint('Restoring tracking for HBL: $hblNo');
        await startTracking(hblNo);
      }
    } catch (e) {
      debugPrint('Error restoring tracking state: $e');
    }
  }

  // Dừng tracking khi đóng app
  Future<void> onAppClose() async {
    await stopTracking();
  }

  // Gửi end location khi dừng tracking
  Future<void> _sendEndLocation() async {
    if (_currentHBL == null) return;

    try {
      // Lấy vị trí cuối cùng
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final token = await AuthService.getToken();
      if (token == null) return;

      final requestBody = {
        'HBLNo': _currentHBL,
        'Latitude': position.latitude.toString(),
        'Longitude': position.longitude.toString(),
        'Timestamp': DateTime.now().toIso8601String(),
        'Accuracy': position.accuracy,
        'Altitude': position.altitude,
        'Speed': position.speed,
        'Heading': position.heading,
        'IsEnd': true, // Đánh dấu đây là end location
      };

      final response = await http.post(
        Uri.parse('$apiBase/api/scan/save-hbl-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('End location sent successfully for HBL: $_currentHBL');
      } else {
        debugPrint('Failed to send end location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending end location: $e');
    }
  }

  // Thêm callback để notify khi trạng thái thay đổi
  void Function()? onTrackingStateChanged;

  void _notifyStateChanged() {
    onTrackingStateChanged?.call();
  }
}
