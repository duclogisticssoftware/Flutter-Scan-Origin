import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String apiBase = 'https://qr.logisticssoftware.vn';

class AppStorage {
  AppStorage._();
  static const FlutterSecureStorage instance = FlutterSecureStorage();
}
