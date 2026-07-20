import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ScanApi (QR / inventory / report)
const String apiBase = kReleaseMode
    ? 'https://qr.logisticssoftware.vn'
    : 'http://localhost:5110';

/// Host NVOAMASIS — truyền lúc build/run:
/// ```
/// flutter run --dart-define=MOBILE_API_BASE=https://localhost:7248
/// flutter build apk --dart-define=MOBILE_API_BASE=https://amasis.nvocc.vn
/// ```
///
/// Đây chỉ là **địa chỉ server API** (`/api/mobile/...`).
/// Multi-DB / multi-tenant: chọn **databaseName** khi login → server + JWT
/// tự nối đúng SQL DB của tenant đó. Không cấu hình tên DB ở đây.
const String _mobileApiBaseDefine = String.fromEnvironment('MOBILE_API_BASE');

String get mobileApiBase {
  final fromEnv = _mobileApiBaseDefine.trim();
  if (fromEnv.isNotEmpty) {
    return fromEnv.endsWith('/')
        ? fromEnv.substring(0, fromEnv.length - 1)
        : fromEnv;
  }
  // Debug: NVOAMASIS local (profile https). Release: prod.
  return kReleaseMode
      ? 'https://amasis.nvocc.vn'
      : 'https://localhost:7248';
}

class AppStorage {
  AppStorage._();

  /// iOS Keychain: first_unlock tránh mất token khi app nền / sau reboot.
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
}
