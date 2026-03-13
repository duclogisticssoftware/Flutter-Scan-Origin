import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Trên mobile/desktop: dùng FilePicker.saveFile (hỗ trợ .xlsx và .pdf).
///
/// Quan trọng: luôn truyền `fileName` kèm đuôi (.xlsx / .pdf) để
/// hệ điều hành nhận đúng định dạng file khi lưu và mở.
Future<String?> saveFile(Uint8List bytes, String fileName) async {
  final lower = fileName.toLowerCase();

  // Giữ nguyên tên file (kể cả đuôi), chỉ dùng allowedExtensions để filter.
  List<String>? extensions;
  FileType type = FileType.any;

  if (lower.endsWith('.xlsx')) {
    type = FileType.custom;
    extensions = ['xlsx'];
  } else if (lower.endsWith('.pdf')) {
    type = FileType.custom;
    extensions = ['pdf'];
  } else {
    // Nếu không rõ đuôi, cho phép chọn .xlsx hoặc .pdf,
    // nhưng vẫn để nguyên tên gốc.
    type = FileType.custom;
    extensions = ['xlsx', 'pdf'];
  }

  return FilePicker.platform.saveFile(
    type: type,
    allowedExtensions: extensions,
    fileName: fileName, // giữ nguyên đuôi file
    bytes: bytes,
  );
}
