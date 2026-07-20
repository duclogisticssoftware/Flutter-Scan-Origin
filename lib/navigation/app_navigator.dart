import 'package:flutter/material.dart';
import 'package:qrscan_app/views/Notifications/phieu_approve_page.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;

  static Future<void> openPhieuApprove(String phieuToken) async {
    final nav = state;
    if (nav == null || phieuToken.isEmpty) return;
    await nav.push(
      MaterialPageRoute(
        builder: (_) => PhieuApprovePage(phieuToken: phieuToken),
      ),
    );
  }
}
