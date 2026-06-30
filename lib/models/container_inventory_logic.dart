/// Logic Container Inventory – map từ API /api/Container/container
/// (bảng Container LMS) sang cấu trúc giống Blazor 8.3.3.
class ContainerInventoryItem {
  ContainerInventoryItem({
    required this.containerNo,
    required this.status,
    required this.depotDisplay,
    required this.agent,
    required this.line,
    required this.sizeType,
    required this.fel,
    required this.inDepot,
    required this.inPort,
    required this.decommission,
    this.seal,
    this.isoCode,
    this.netWeight,
    this.updatedAt,
    this.condition,
    this.sourceTable = 'Container',
  });

  final String containerNo;
  final String status;
  final String depotDisplay;
  final String agent;
  final String line;
  final String sizeType;
  final String fel;
  final String inDepot;
  final String inPort;
  final bool decommission;
  final String? seal;
  final String? isoCode;
  final double? netWeight;
  final DateTime? updatedAt;
  final String? condition;
  final String sourceTable;

  String get containerKey =>
      containerNo.trim().isNotEmpty ? containerNo.trim() : '';

  bool get isEmptyFel {
    final f = fel.trim().toUpperCase();
    return f == 'E' || f == 'EMPTY' || f == 'R' || f == 'MT';
  }

  bool get isFullFel {
    final f = fel.trim().toUpperCase();
    return f == 'F' || f == 'FULL' || f == 'L' || f == 'LADEN';
  }

  bool get isDamaged =>
      decommission ||
      _looksDamaged(condition) ||
      _looksDamaged(fel);

  bool get isDamagedOrDFel {
    final f = fel.trim().toUpperCase();
    return f == 'D' ||
        f == 'DAM' ||
        f == 'DAMAGE' ||
        f == 'DAMAGED' ||
        isDamaged;
  }

  static bool _looksDamaged(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final v = value.trim().toUpperCase();
    return v.contains('DAM') ||
        v.contains('HONG') ||
        v.contains('HƯ') ||
        v.contains('MOOP') ||
        v.contains('MOP') ||
        v.contains('BỂ') ||
        v.contains('BE ');
  }

  static ContainerInventoryItem fromMap(Map<String, dynamic> c) {
    final containerNo = _str(c, [
      'CONTAINER_NO',
      'container_NO',
      'containerNo',
      'containeR_NO',
    ]);
    final sizeRaw = _str(c, [
      'CTN_SIZE_TYPE',
      'ctN_SIZE_TYPE',
      'ctn_SIZE_TYPE',
      'ctnSizeType',
    ]);
    final statusRaw = _str(c, [
      'NVOCC_Status',
      'nvocC_Status',
      'nvoCC_Status',
      'nvoCCStatus',
    ]);
    final inDepot = _str(c, ['In_Depot', 'in_Depot', 'inDepot']);
    final inPort = _str(c, ['In_Port', 'in_Port', 'inPort']);
    final agent = _firstNonEmpty([
      _str(c, ['OwnerType', 'ownerType']),
      _str(c, ['USERID', 'userid', 'userId']),
    ]);
    final line = _firstNonEmpty([
      _str(c, ['loaihang', 'Loaihang']),
      _str(c, ['Status_Cont', 'status_Cont', 'statusCont']),
    ]);
    final fel = _firstNonEmpty([
      _str(c, ['loaihang', 'Loaihang']),
      _str(c, ['Condition', 'condition']),
      _str(c, ['Status', 'status']),
    ]);
    final depotDisplay = _firstNonEmpty([inDepot, inPort, 'N/A']);

    return ContainerInventoryItem(
      containerNo: containerNo,
      status: _normalizeStatus(statusRaw),
      depotDisplay: depotDisplay,
      agent: agent.isEmpty ? 'N/A' : agent,
      line: line.isEmpty ? 'N/A' : line,
      sizeType: detectSizeType(sizeRaw),
      fel: fel,
      inDepot: inDepot,
      inPort: inPort,
      decommission: _bool(c, ['Decommision', 'decommision']),
      seal: _str(c, ['Seal', 'seal']),
      isoCode: _str(c, ['IsoCode', 'isoCode']),
      netWeight: _double(c, ['NETWEIGHT', 'netweight', 'netWeight']),
      updatedAt: _date(c, ['UPDATETIME', 'updatetime', 'updateTime']),
      condition: _str(c, ['Condition', 'condition']),
    );
  }

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    bool hit(String? v) => v != null && v.toLowerCase().contains(q);
    return hit(containerNo) ||
        hit(depotDisplay) ||
        hit(agent) ||
        hit(line) ||
        hit(inDepot) ||
        hit(inPort) ||
        hit(sizeType) ||
        hit(fel) ||
        hit(seal) ||
        hit(isoCode) ||
        hit(status) ||
        hit(condition) ||
        hit(sourceTable);
  }

  bool matchesFelFilter(String? filter) {
    if (filter == null || filter.isEmpty) return true;
    switch (filter.toUpperCase()) {
      case 'E':
        return isEmptyFel;
      case 'F':
        return isFullFel;
      case 'D':
        return isDamagedOrDFel;
      default:
        return true;
    }
  }
}

class ContainerGroupRow {
  ContainerGroupRow({
    required this.depot,
    required this.agent,
    required this.line,
    required this.containerType,
    required this.containerCount,
    required this.emptyCount,
    required this.fullCount,
    required this.damagedCount,
    required this.otherFelCount,
  });

  final String depot;
  final String agent;
  final String line;
  final String containerType;
  final int containerCount;
  final int emptyCount;
  final int fullCount;
  final int damagedCount;
  final int otherFelCount;
}

class ContainerInventoryFilter {
  String search = '';
  String? agent;
  String? line;
  String? depot;
  String? sizeType;
  String? status;
  String? fel;
  bool excludeDamaged = false;
}

const statusInDepot = 'In Depot';
const statusWaitingPort = 'Waiting Port Arrival';
const statusArrivedPort = 'Arrived at Port';
const statusInTransit = 'In Transit';

List<ContainerInventoryItem> parseContainerList(List<dynamic> rawList) {
  final list = <ContainerInventoryItem>[];
  for (final e in rawList) {
    if (e is Map<String, dynamic>) {
      list.add(ContainerInventoryItem.fromMap(e));
    } else if (e is Map) {
      list.add(ContainerInventoryItem.fromMap(Map<String, dynamic>.from(e)));
    }
  }
  return list.where((x) => x.containerKey.isNotEmpty).toList();
}

List<ContainerInventoryItem> applyFilters(
  List<ContainerInventoryItem> records,
  ContainerInventoryFilter filter,
) {
  return records.where((x) {
    if (filter.excludeDamaged && x.isDamaged) return false;
    if (filter.agent != null &&
        filter.agent!.isNotEmpty &&
        x.agent.toLowerCase() != filter.agent!.toLowerCase()) {
      return false;
    }
    if (filter.line != null &&
        filter.line!.isNotEmpty &&
        x.line.toLowerCase() != filter.line!.toLowerCase()) {
      return false;
    }
    if (filter.depot != null &&
        filter.depot!.isNotEmpty &&
        x.depotDisplay.toLowerCase() != filter.depot!.toLowerCase()) {
      return false;
    }
    if (filter.sizeType != null &&
        filter.sizeType!.isNotEmpty &&
        x.sizeType.toLowerCase() != filter.sizeType!.toLowerCase()) {
      return false;
    }
    if (filter.status != null &&
        filter.status!.isNotEmpty &&
        x.status.toLowerCase() != filter.status!.toLowerCase()) {
      return false;
    }
    if (!x.matchesFelFilter(filter.fel)) return false;
    if (!x.matchesSearch(filter.search)) return false;
    return true;
  }).toList();
}

List<ContainerGroupRow> buildGroupRows(List<ContainerInventoryItem> rows) {
  final map = <String, List<ContainerInventoryItem>>{};
  for (final x in rows) {
    final key = '${x.depotDisplay}|${x.agent}|${x.line}|${x.sizeType}';
    map.putIfAbsent(key, () => []).add(x);
  }

  final result = map.entries.map((e) {
    final list = e.value;
    final keys = list.map((x) => x.containerKey.toLowerCase()).toSet();
    int countFel(bool Function(ContainerInventoryItem) fn) => list
        .where(fn)
        .map((x) => x.containerKey.toLowerCase())
        .toSet()
        .length;

    final first = list.first;
    return ContainerGroupRow(
      depot: first.depotDisplay,
      agent: first.agent,
      line: first.line,
      containerType: first.sizeType,
      containerCount: keys.length,
      emptyCount: countFel((x) => x.isEmptyFel),
      fullCount: countFel((x) => x.isFullFel),
      damagedCount: countFel((x) => x.isDamagedOrDFel),
      otherFelCount: countFel(
        (x) => !x.isEmptyFel && !x.isFullFel && !x.isDamagedOrDFel,
      ),
    );
  }).toList();

  result.sort((a, b) {
    final d = a.depot.compareTo(b.depot);
    if (d != 0) return d;
    final l = a.line.compareTo(b.line);
    if (l != 0) return l;
    return a.containerType.compareTo(b.containerType);
  });
  return result;
}

String detectSizeType(String? isoOrSize) {
  if (isoOrSize == null || isoOrSize.trim().isEmpty) return 'OTHER';
  final s = isoOrSize.trim().toUpperCase();
  if (s.startsWith('20') || s.contains('20DC') || s.contains('20GP')) {
    return '20DC';
  }
  if (s.startsWith('40') ||
      s.contains('40HC') ||
      s.contains('40HQ') ||
      s.contains('45')) {
    return '40HC';
  }
  return 'OTHER';
}

String _normalizeStatus(String raw) {
  final s = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (s == 'in depot') return statusInDepot;
  if (s == 'waiting port arrival') return statusWaitingPort;
  if (s == 'arrived at port') return statusArrivedPort;
  if (s == 'in transit') return statusInTransit;
  if (s.isEmpty) return statusInDepot;
  return raw.trim();
}

String _str(Map<String, dynamic> c, List<String> keys) {
  for (final k in keys) {
    final v = c[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return '';
}

String _firstNonEmpty(List<String> values) {
  for (final v in values) {
    if (v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

bool _bool(Map<String, dynamic> c, List<String> keys) {
  for (final k in keys) {
    final v = c[k];
    if (v == null) continue;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
  }
  return false;
}

double? _double(Map<String, dynamic> c, List<String> keys) {
  for (final k in keys) {
    final v = c[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(v.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _date(Map<String, dynamic> c, List<String> keys) {
  for (final k in keys) {
    final v = c[k];
    if (v == null) continue;
    if (v is DateTime) return v;
    final parsed = DateTime.tryParse(v.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String exportInventoryCsv(List<ContainerInventoryItem> rows) {
  final buffer = StringBuffer();
  buffer.writeln(
    'SourceTable,Status,AGENT,LINE,DEPOT,Container,SizeType,FEL,InDepot,InPort,Decommision,Seal,NetWeight,UpdatedAt',
  );
  for (final x in rows) {
    buffer.writeln([
      _csv(x.sourceTable),
      _csv(x.status),
      _csv(x.agent),
      _csv(x.line),
      _csv(x.depotDisplay),
      _csv(x.containerNo),
      _csv(x.sizeType),
      _csv(x.fel),
      _csv(x.inDepot),
      _csv(x.inPort),
      _csv(x.decommission ? 'Y' : 'N'),
      _csv(x.seal ?? ''),
      _csv(x.netWeight?.toString() ?? ''),
      _csv(x.updatedAt?.toIso8601String() ?? ''),
    ].join(','));
  }
  return buffer.toString();
}

String _csv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
