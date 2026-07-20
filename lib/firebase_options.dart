import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options — sinh từ `android/app/google-services.json` (project: lms-qrscan).
class DefaultFirebaseOptions {
  static bool get isConfigured {
    if (kIsWeb) return false;
    try {
      final o = currentPlatform;
      return o.apiKey.isNotEmpty &&
          o.apiKey != 'REPLACE_ME' &&
          o.projectId.isNotEmpty &&
          o.projectId != 'REPLACE_ME' &&
          o.appId.isNotEmpty &&
          o.appId != 'REPLACE_ME';
    } catch (_) {
      return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('FCM web chưa bật trong app này.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FCM chỉ hỗ trợ Android/iOS trong app này.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNXW5TC1hcVAGGaTFEKQECjD7rNPOWP2M',
    appId: '1:171373076136:android:2dd402ef3c208c770eac9d',
    messagingSenderId: '171373076136',
    projectId: 'lms-qrscan',
    storageBucket: 'lms-qrscan.firebasestorage.app',
  );

  /// iOS — từ `ios/Runner/GoogleService-Info.plist` (bundle: com.vinalink.qrscan-app-vinalink)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjsdZQtFaW479tWTzxksJ-tURXSvwvxfI',
    appId: '1:171373076136:ios:8b4af8d92cac17c80eac9d',
    messagingSenderId: '171373076136',
    projectId: 'lms-qrscan',
    storageBucket: 'lms-qrscan.firebasestorage.app',
    iosBundleId: 'com.vinalink.qrscan-app-vinalink',
  );
}
