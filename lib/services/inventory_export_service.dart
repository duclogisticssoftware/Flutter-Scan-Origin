import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Converts inventory grouped rows to Excel bytes (one sheet).
/// [rows] each has location, containerCount, sizeCounts map, decommissionCount.
/// Matches C# InventoryExportService.AddSheet structure.
Uint8List? exportInventoryToExcel({
  required String sheetName,
  required String locationHeader,
  required List<InventoryExportRow> rows,
  required List<String> sizeTypes,
  String decommissionHeader = 'Decommision',
}) {
  try {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet() ?? 'Sheet1';
    // Tên sheet Excel tối đa 31 ký tự, không chứa \ / ? * [ ]
    final safeSheetName = sheetName.length > 31
        ? sheetName.substring(0, 31)
        : sheetName.replaceAll(RegExp(r'[\\/?*\[\]]'), '_');
    excel.rename(defaultName, safeSheetName);
    final sheet = excel[safeSheetName];

  int row = 0;

  // Title row
  final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
  titleCell.value = TextCellValue(sheetName);
  titleCell.cellStyle = CellStyle(bold: true);
  row += 2;

  // Header row
  int col = 0;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(locationHeader);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue('CONTAINER COUNT');
  for (final st in sizeTypes) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(st);
  }
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = TextCellValue(decommissionHeader);
  final headerRowIndex = row;
  row++;

  // Data rows
  for (final r in rows) {
    col = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(r.location);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = IntCellValue(r.containerCount);
    for (final st in sizeTypes) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = IntCellValue(r.getSizeCount(st));
    }
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = IntCellValue(r.decommissionCount);
    row++;
  }

  // Bold header
  for (int c = 0; c <= sizeTypes.length + 2; c++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIndex));
    cell.cellStyle = CellStyle(bold: true);
  }

  final bytes = excel.encode();
  return bytes != null ? Uint8List.fromList(bytes) : null;
  } catch (e, stack) {
    throw Exception('exportInventoryToExcel: $e\n$stack');
  }
}

/// DTO for one row in inventory export (same as C# InventoryExportRow).
class InventoryExportRow {
  final String location;
  final int containerCount;
  final Map<String, int> sizeCounts;
  final int decommissionCount;

  InventoryExportRow({
    required this.location,
    required this.containerCount,
    required this.sizeCounts,
    required this.decommissionCount,
  });

  int getSizeCount(String sizeType) {
    if (sizeType.isEmpty) return 0;
    return sizeCounts[sizeType] ?? 0;
  }
}

String _escapeHtml(String s) {
  if (s.isEmpty) return s;
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Generates a full HTML document for printing (browser print → Save as PDF).
/// Matches C# ExportService.GetSingleTablePrintHtml.
String getSingleTablePrintHtml({
  required List<InventoryExportRow> rows,
  required List<String> sizeTypes,
  required String title,
  required String locationHeader,
  String decommissionHeader = 'Decommision',
}) {
  final sb = StringBuffer();
  sb.write('<!DOCTYPE html><html><head><meta charset="utf-8"><title>');
  sb.write(_escapeHtml(title));
  sb.write('</title><style>');
  sb.write('table{border-collapse:collapse;width:100%;}');
  sb.write('th,td{border:1px solid #333;padding:6px 10px;text-align:left;}');
  sb.write('th{background:#eee;font-weight:bold;}');
  sb.write('h1{margin-bottom:12px;}');
  sb.write('</style></head><body><h1>');
  sb.write(_escapeHtml(title));
  sb.write('</h1><table><thead><tr>');
  sb.write('<th>');
  sb.write(_escapeHtml(locationHeader));
  sb.write('</th><th>CONTAINER COUNT</th>');
  for (final st in sizeTypes) {
    sb.write('<th>');
    sb.write(_escapeHtml(st));
    sb.write('</th>');
  }
  sb.write('<th>');
  sb.write(_escapeHtml(decommissionHeader));
  sb.write('</th></tr></thead><tbody>');
  for (final r in rows) {
    sb.write('<tr><td>');
    sb.write(_escapeHtml(r.location));
    sb.write('</td><td>');
    sb.write(r.containerCount.toString());
    sb.write('</td>');
    for (final st in sizeTypes) {
      sb.write('<td>');
      sb.write(r.getSizeCount(st).toString());
      sb.write('</td>');
    }
    sb.write('<td>');
    sb.write(r.decommissionCount.toString());
    sb.write('</td></tr>');
  }
  sb.write('</tbody></table></body></html>');
  return sb.toString();
}

/// Generates PDF bytes for the same table (web + Android/iOS). Use with saveFile to download/save.
Future<Uint8List?> exportInventoryToPdf({
  required List<InventoryExportRow> rows,
  required List<String> sizeTypes,
  required String title,
  required String locationHeader,
  String decommissionHeader = 'Decommision',
}) async {
  try {
    final doc = pw.Document();
    final headerCells = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(locationHeader, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('CONTAINER COUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
      for (final st in sizeTypes)
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(st, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(decommissionHeader, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
    ];
    final dataRows = <pw.TableRow>[
      pw.TableRow(children: headerCells),
      for (final r in rows)
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.location)),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.containerCount.toString())),
            for (final st in sizeTypes)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(r.getSizeCount(st).toString()),
              ),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.decommissionCount.toString())),
          ],
        ),
    ];
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: dataRows,
            ),
          ],
        ),
      ),
    );
    return await doc.save();
  } catch (e, stack) {
    throw Exception('exportInventoryToPdf: $e\n$stack');
  }
}
