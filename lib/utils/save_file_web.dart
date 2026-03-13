import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Trên web: tạo Blob và trigger download (FilePicker.saveFile chưa implement trên web).
Future<String?> saveFile(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final downloadName = fileName.endsWith('.xlsx') || fileName.endsWith('.pdf')
      ? fileName
      : '$fileName.xlsx';
  final anchor = html.AnchorElement()
    ..href = url
    ..download = downloadName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  return null;
}
