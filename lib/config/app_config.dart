import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String apiBase = kReleaseMode
    ? 'https://qr.logisticssoftware.vn'
    : 'http://localhost:5110';

class AppStorage {
  AppStorage._();
  static const FlutterSecureStorage instance = FlutterSecureStorage();
}
