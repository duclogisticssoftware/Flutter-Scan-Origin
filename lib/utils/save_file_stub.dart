import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Trên mobile/desktop: dùng FilePicker.saveFile (hỗ trợ .xlsx và .pdf).
Future<String?> saveFile(Uint8List bytes, String fileName) async {
  String nameWithoutExt = fileName;
  List<String> extensions = ['xlsx'];
  if (fileName.endsWith('.xlsx')) {
    nameWithoutExt = fileName.replaceAll('.xlsx', '');
    extensions = ['xlsx'];
  } else if (fileName.endsWith('.pdf')) {
    nameWithoutExt = fileName.replaceAll('.pdf', '');
    extensions = ['pdf'];
  } else {
    nameWithoutExt = fileName;
    extensions = ['xlsx', 'pdf'];
  }
  return FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: extensions,
    fileName: nameWithoutExt,
    bytes: bytes,
  );
}
