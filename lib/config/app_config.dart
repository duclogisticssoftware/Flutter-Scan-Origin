import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ScanApi (QR / inventory / report)
const String apiBase = kReleaseMode
    ? 'https://qr.logisticssoftware.vn'
    : 'http://localhost:5110';

/// Host NVOAMASIS — truyền lúc build/run, không gắn 1 domain cứng trong logic app:
/// ```
/// flutter run --dart-define=MOBILE_API_BASE=https://amasis.nvocc.vn
/// flutter build apk --dart-define=MOBILE_API_BASE=https://your-prod-host
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
  // Fallback khi quên truyền dart-define (dev). Prod nên luôn set MOBILE_API_BASE.
  return 'https://amasis.nvocc.vn';
}

class AppStorage {
  AppStorage._();
  static const FlutterSecureStorage instance = FlutterSecureStorage();
}
