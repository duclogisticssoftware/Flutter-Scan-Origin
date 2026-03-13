// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens HTML in a new window via Blob URL and triggers print (Save as PDF).
/// Avoids touching .document on _DOMWindowCrossFrame; only uses .print() after load.
Future<void> printInventoryHtml(String htmlContent) async {
  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final w = html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  // ignore: unnecessary_null_comparison, dead_code
  if (w == null) return;
  // ignore: dead_code
  final win = w as dynamic;
  final window = html.window as dynamic;
  window.setTimeout(() {
    try {
      win.print();
    } catch (_) {}
  }, 500);
}
