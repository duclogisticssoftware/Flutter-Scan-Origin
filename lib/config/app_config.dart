import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// const String apiBase = 'https://899730878b4f.ngrok-free.app';
const String apiBase = 'https://qr.logisticssoftware.vn';
// const String apiBase = 'http://localhost:5110';

class AppStorage {
  AppStorage._();
  static const FlutterSecureStorage instance = FlutterSecureStorage();
}
