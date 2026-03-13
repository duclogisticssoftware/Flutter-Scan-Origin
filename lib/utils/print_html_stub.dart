/// Stub for non-web: no-op. Caller should check kIsWeb and show message instead.
Future<void> printInventoryHtml(String htmlContent) async {
  // Not used on non-web; screen shows "PDF/Print only on web".
}
