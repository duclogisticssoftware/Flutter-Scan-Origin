import 'package:flutter/material.dart';

class CiColumn {
  const CiColumn(this.label, this.keys, {this.isDate = false, this.alignRight = false});

  final String label;
  final List<String> keys;
  final bool isDate;
  final bool alignRight;
}

const containerDetailColumns = [
  CiColumn('DEPOT', ['depotDisplay']),
  CiColumn('Container', ['itemNo', 'iteM_NO', 'ITEM_NO']),
  CiColumn('YOM', ['yom', 'YOM']),
  CiColumn('IN / OUT', ['movementDisplay']),
  CiColumn('Last Event', ['eventTs', 'eventTS'], isDate: true),
  CiColumn('Gate In', ['arr_TS', 'arrTs', 'ARR_TS'], isDate: true),
  CiColumn('Time In', ['timE_IN', 'timeIn', 'TIME_IN']),
  CiColumn('Gate Out', ['dep_TS', 'depTs', 'DEP_TS'], isDate: true),
  CiColumn('DEM Days', ['demGrossDays'], alignRight: true),
  CiColumn('DEM Billable', ['demBillableDays'], alignRight: true),
  CiColumn('DET Days', ['detGrossDays'], alignRight: true),
  CiColumn('DET Billable', ['detBillableDays'], alignRight: true),
  CiColumn('INS Date', ['ins_DATE', 'insDate', 'INS_DATE'], isDate: true),
  CiColumn('Customs', ['cC_TS', 'ccTs', 'CC_TS'], isDate: true),
  CiColumn('Clean Method', ['cleaN_METHOD', 'cleanMethod', 'CLEAN_METHOD']),
  CiColumn('Clean Status', ['cleaN_STATUS', 'cleanStatus', 'CLEAN_STATUS']),
  CiColumn('PTI Date', ['ptI_DATE', 'ptiDate', 'PTI_DATE'], isDate: true),
  CiColumn('Status', ['status']),
  CiColumn('Load F/E', ['loadStatusDisplay']),
  CiColumn('Damage', ['damageDisplay']),
  CiColumn('ISO / Size', ['iso', 'ISO']),
  CiColumn('Size Group', ['sizeType']),
  CiColumn('WEIGHT', ['weight', 'WEIGHT'], alignRight: true),
  CiColumn('VGM', ['vgm_WEIGHT', 'vgmWeight', 'VGM_WEIGHT'], alignRight: true),
  CiColumn('Bill', ['booK_NO', 'bookNo', 'BOOK_NO']),
  CiColumn('B/L', ['bilL_OF_LADING', 'billOfLading', 'BILL_OF_LADING']),
  CiColumn('Seal', ['soseal', 'SOSEAL']),
  CiColumn('LINE', ['line', 'LINE']),
  CiColumn('AGENT', ['agent', 'AGENT']),
  CiColumn('Location', ['currentLocationDisplay']),
  CiColumn('Shipper', ['shipper', 'SHIPPER']),
  CiColumn('Note', ['ghichu', 'GHICHU']),
  CiColumn('Source', ['sourceTable']),
];

const containerEventColumns = [
  CiColumn('DEPOT', ['depotDisplay']),
  CiColumn('Container', ['itemNo', 'iteM_NO', 'ITEM_NO']),
  CiColumn('IN / OUT', ['movementDisplay']),
  CiColumn('Event Time', ['eventTs', 'eventTS'], isDate: true),
  CiColumn('Gate In', ['arr_TS', 'arrTs', 'ARR_TS'], isDate: true),
  CiColumn('Gate Out', ['dep_TS', 'depTs', 'DEP_TS'], isDate: true),
  CiColumn('DEM Days', ['demGrossDays'], alignRight: true),
  CiColumn('DEM Billable', ['demBillableDays'], alignRight: true),
  CiColumn('DET Days', ['detGrossDays'], alignRight: true),
  CiColumn('DET Billable', ['detBillableDays'], alignRight: true),
  CiColumn('Status', ['status']),
  CiColumn('Load F/E', ['loadStatusDisplay']),
  CiColumn('Damage', ['damageDisplay']),
  CiColumn('Bill', ['booK_NO', 'bookNo', 'BOOK_NO']),
  CiColumn('B/L', ['bilL_OF_LADING', 'billOfLading', 'BILL_OF_LADING']),
  CiColumn('Seal', ['soseal', 'SOSEAL']),
  CiColumn('Method', ['eventMethod']),
  CiColumn('Reason', ['statusReason']),
  CiColumn('Source', ['sourceTable']),
];

String ciRecordValue(Map<String, dynamic> row, CiColumn column) {
  for (final key in column.keys) {
    final value = row[key];
    if (value == null) continue;
    if (value is num && column.isDate) continue;
    final text = column.isDate ? formatCiDate(value) : '$value';
    if (text.isNotEmpty) return text;
  }
  return '';
}

String formatCiDate(dynamic value) {
  if (value == null) return '';
  if (value is String && value.isEmpty) return '';
  DateTime? dt;
  if (value is DateTime) {
    dt = value;
  } else {
    dt = DateTime.tryParse(value.toString());
  }
  if (dt == null) return value.toString();
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} $h:$min';
}

String ciContainerKey(Map<String, dynamic> row) {
  final container = ciRecordValue(row, const CiColumn('', ['itemNo', 'iteM_NO', 'ITEM_NO']));
  return '${row['containerKey'] ?? container}';
}

Widget buildCiDataTable({
  required List<CiColumn> columns,
  required List<dynamic> rows,
  Color? headingColor,
  String? selectedKey,
  ValueChanged<String>? onRowTap,
  int? selectedRowIndex,
}) {
  return DataTable(
    headingRowHeight: 40,
    dataRowMinHeight: 36,
    dataRowMaxHeight: 48,
    headingRowColor: headingColor != null
        ? WidgetStatePropertyAll(headingColor)
        : null,
    columns: columns
        .map((c) => DataColumn(
              label: Text(
                c.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ))
        .toList(),
    rows: List.generate(rows.length, (i) {
      final row = rows[i] as Map<String, dynamic>;
      final key = ciContainerKey(row);
      final selected = selectedKey != null && selectedKey == key;
      return DataRow(
        selected: selected || selectedRowIndex == i,
        color: selected
            ? WidgetStatePropertyAll(headingColor?.withValues(alpha: 0.35) ?? const Color(0xFFE3F2FD))
            : (i.isEven ? const WidgetStatePropertyAll(Color(0xFFF7FAFC)) : null),
        onSelectChanged: onRowTap != null ? (_) => onRowTap(key) : null,
        cells: columns
            .map((c) => DataCell(
                  Align(
                    alignment:
                        c.alignRight ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      ciRecordValue(row, c),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: c.label == 'Container' || c.label == 'DEPOT'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ))
            .toList(),
      );
    }),
  );
}
