import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:qrscan_app/services/address_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _scanHistory = [];
  bool _loading = true;
  String? _error;
  Map<String, String> _addresses = {}; // Cache địa chỉ theo tọa độ
  Map<String, dynamic> _mapData = {}; // Thông tin map data

  @override
  void initState() {
    super.initState();
    // Không gọi _loadHistory() ở đây để tránh lỗi inherited widgets
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gọi _loadHistory() ở đây thay vì initState()
    print(
      '[HISTORY] didChangeDependencies - scanHistory: ${_scanHistory.length}, loading: $_loading',
    );
    if (_scanHistory.isEmpty) {
      print('[HISTORY] Starting to load history...');
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    print('[HISTORY] _loadHistory() started');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hblNo = _getHBLForQuery();
      print('[HISTORY] HBL for query: "$hblNo"');

      // API all-hbl-locations không cần HBL cụ thể, luôn gọi API

      // Sử dụng API all-hbl-locations để lấy dữ liệu tất cả HBL
      print('[HISTORY] Calling API: $apiBase/api/scan/all-hbl-locations');

      final response = await http.post(
        Uri.parse('$apiBase/api/scan/all-hbl-locations'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HISTORY] API Response status: ${response.statusCode}');
      print('[HISTORY] API Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[HISTORY] API call successful, processing response...');
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> hbls = data['hbls'] ?? [];
        final int totalHBLs = data['totalHBLs'] ?? 0;
        final int totalLocations = data['totalLocations'] ?? 0;

        print('[HISTORY] Total HBLs: $totalHBLs');
        print('[HISTORY] Total locations: $totalLocations');
        print('[HISTORY] HBLs data: ${hbls.length}');

        // Convert tất cả locations từ tất cả HBLs thành format scan history
        final List<Map<String, dynamic>> allScanHistory = [];

        for (final hblData in hbls) {
          final hblInfo = hblData['hblInfo'] ?? {};
          final mapData = hblData['mapData'] ?? {};
          final List<dynamic> locations = hblData['locations'] ?? [];

          for (final location in locations) {
            allScanHistory.add({
              'id': location['id'],
              'scannedId': hblInfo['hblNo'],
              'hblID': hblInfo['hblID'],
              'scannedAt': location['timestamp'],
              'latitude': location['latitude'].toString(),
              'longitude': location['longitude'].toString(),
              'sequence': location['sequence'],
              'isStart': location['isStart'],
              'isEnd': location['isEnd'],
              'timeFromStart': location['timeFromStart'],
              'accuracy': location['accuracy'],
              'altitude': location['altitude'],
              'speed': location['speed'],
              'heading': location['heading'],
              'createdAt': location['createdAt'],
              'hblInfo': hblInfo,
              'mapData': mapData,
            });
          }
        }

        // Sắp xếp theo timestamp để hiển thị timeline
        allScanHistory.sort(
          (a, b) => DateTime.parse(
            a['scannedAt'],
          ).compareTo(DateTime.parse(b['scannedAt'])),
        );

        print(
          '[HISTORY] Setting state with ${allScanHistory.length} items from ${hbls.length} HBLs',
        );
        setState(() {
          _scanHistory = allScanHistory;
          _mapData = {'totalHBLs': totalHBLs, 'totalLocations': totalLocations};
        });

        // Load địa chỉ cho tất cả scan items
        print('[HISTORY] Loading addresses...');
        _loadAllAddresses();
        print('[HISTORY] History loaded successfully');
      } else {
        print('[HISTORY] API call failed with status: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load HBL map data (${response.statusCode})';
        });
      }
    } catch (e) {
      print('[HISTORY] Exception occurred: $e');
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      print('[HISTORY] Setting loading to false');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HBL History'),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingWidget(isSmallScreen)
          : _error != null
          ? _buildErrorWidget(isSmallScreen)
          : _scanHistory.isEmpty
          ? _buildEmptyWidget(isSmallScreen)
          : _buildContent(isSmallScreen, isTablet),
    );
  }

  Widget _buildLoadingWidget(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ThemeColors.getPrimaryColor(context),
            ),
            strokeWidth: isSmallScreen ? 2 : 3,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Loading HBL history...',
            style: ThemeColors.getSubtitleStyle(
              context,
            ).copyWith(fontSize: isSmallScreen ? 14 : 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isSmallScreen ? 48 : 64,
            color: const Color(0xFFD32F2F),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            _error!,
            style: ThemeColors.getErrorStyle(
              context,
            ).copyWith(fontSize: isSmallScreen ? 14 : 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: isSmallScreen ? 48 : 64,
            color: const Color(0xFF666666),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'No scan history yet',
            style: ThemeColors.getSubtitleStyle(
              context,
            ).copyWith(fontSize: isSmallScreen ? 16 : 18),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Start scanning HBLs to see their journey here',
            style: ThemeColors.getHintStyle(
              context,
            ).copyWith(fontSize: isSmallScreen ? 12 : 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen, bool isTablet) {
    return Column(
      children: [
        if (_mapData.isNotEmpty) _buildMovementSummary(),
        Expanded(child: _buildHBLList(isSmallScreen, isTablet)),
      ],
    );
  }

  /// Hiển thị thông tin tổng quan về tất cả HBLs
  Widget _buildMovementSummary() {
    final totalHBLs = _mapData['totalHBLs'] ?? 0;
    final totalLocations = _mapData['totalLocations'] ?? _scanHistory.length;
    final totalDistance = _calculateTotalDistance();
    final duration = _calculateDuration();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'All HBLs Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.qr_code,
                    label: 'Total HBLs',
                    value: '$totalHBLs',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.location_on,
                    label: 'Total Locations',
                    value: '$totalLocations points',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.straighten,
                    label: 'Total Distance',
                    value: '${totalDistance.toStringAsFixed(2)} km',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: duration,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Hiển thị danh sách các HBLs với map riêng cho từng HBL
  Widget _buildHBLList(bool isSmallScreen, bool isTablet) {
    if (_scanHistory.isEmpty) {
      return _buildEmptyWidget(isSmallScreen);
    }

    // Nhóm locations theo HBL
    final Map<String, List<Map<String, dynamic>>> hblGroups = {};
    for (final item in _scanHistory) {
      final hblNo = item['scannedId'] ?? 'Unknown';
      if (!hblGroups.containsKey(hblNo)) {
        hblGroups[hblNo] = [];
      }
      hblGroups[hblNo]!.add(item);
    }

    return ListView.builder(
      itemCount: hblGroups.length,
      itemBuilder: (context, index) {
        final hblEntry = hblGroups.entries.toList()[index];
        final hblNo = hblEntry.key;
        final locations = hblEntry.value;

        // Sắp xếp locations theo thời gian
        locations.sort(
          (a, b) => DateTime.parse(
            a['scannedAt'],
          ).compareTo(DateTime.parse(b['scannedAt'])),
        );

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HBL Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.getPrimaryColor(context).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: ThemeColors.getPrimaryColor(context),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HBL: $hblNo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.getPrimaryColor(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${locations.length} locations',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Map cho HBL này
              Container(
                height: 300,
                child: _buildSingleHBLMap(locations, hblNo),
              ),

              // Timeline cho HBL này
              _buildHBLTimeline(locations, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  /// Hiển thị map cho một HBL cụ thể
  Widget _buildSingleHBLMap(
    List<Map<String, dynamic>> locations,
    String hblNo,
  ) {
    if (locations.isEmpty) {
      return const Center(child: Text('No location data'));
    }

    final bounds = _calculateHBLBounds(locations);
    final center = _calculateHBLCenter(locations);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          center: center,
          zoom: _calculateOptimalZoom(bounds),
          minZoom: 3.0,
          maxZoom: 18.0,
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.vinalink.qrscan',
          ),
          // Polyline cho HBL này
          PolylineLayer(
            polylines: [
              Polyline(
                points: locations
                    .where(
                      (item) =>
                          item['latitude'] != null && item['longitude'] != null,
                    )
                    .map(
                      (item) => LatLng(
                        double.parse(item['latitude'].toString()),
                        double.parse(item['longitude'].toString()),
                      ),
                    )
                    .toList(),
                strokeWidth: 4.0,
                color: ThemeColors.getPrimaryColor(context),
              ),
            ],
          ),
          // Markers cho HBL này
          MarkerLayer(markers: _buildHBLMarkers(locations)),
        ],
      ),
    );
  }

  /// Hiển thị timeline cho một HBL (compact version)
  Widget _buildHBLTimeline(
    List<Map<String, dynamic>> locations,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Timeline (${locations.length} points)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Compact timeline với horizontal scroll
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final sequence = location['sequence'] ?? (index + 1);
                final isStart = location['isStart'] == true || index == 0;
                final isEnd =
                    location['isEnd'] == true || index == locations.length - 1;

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      // Marker
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isStart
                              ? Colors.green
                              : isEnd
                              ? Colors.red
                              : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            isStart
                                ? 'S'
                                : isEnd
                                ? 'E'
                                : '$sequence',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Time
                      Text(
                        _formatTime(location['scannedAt']),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Sequence
                      Text(
                        isStart
                            ? 'Start'
                            : isEnd
                            ? 'End'
                            : 'P$sequence',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Format time ngắn gọn
  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  /// Tính toán bounds cho một HBL cụ thể
  LatLngBounds _calculateHBLBounds(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      return LatLngBounds(LatLng(10.7, 106.6), LatLng(10.8, 106.7));
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final location in locations) {
      if (location['latitude'] != null && location['longitude'] != null) {
        final lat = double.parse(location['latitude'].toString());
        final lng = double.parse(location['longitude'].toString());

        minLat = minLat < lat ? minLat : lat;
        maxLat = maxLat > lat ? maxLat : lat;
        minLng = minLng < lng ? minLng : lng;
        maxLng = maxLng > lng ? maxLng : lng;
      }
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  /// Tính toán center cho một HBL cụ thể
  LatLng _calculateHBLCenter(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      return LatLng(10.7, 106.6); // Default to Ho Chi Minh City
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final location in locations) {
      if (location['latitude'] != null && location['longitude'] != null) {
        totalLat += double.parse(location['latitude'].toString());
        totalLng += double.parse(location['longitude'].toString());
        count++;
      }
    }

    if (count == 0) return LatLng(10.7, 106.6);

    return LatLng(totalLat / count, totalLng / count);
  }

  /// Tạo markers cho một HBL cụ thể
  List<Marker> _buildHBLMarkers(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return [];

    final markers = <Marker>[];

    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      if (location['latitude'] != null && location['longitude'] != null) {
        final lat = double.parse(location['latitude'].toString());
        final lng = double.parse(location['longitude'].toString());
        final sequence = location['sequence'] ?? (i + 1);
        final isStart = location['isStart'] == true || i == 0;
        final isEnd = location['isEnd'] == true || i == locations.length - 1;

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: isStart
                    ? Colors.green
                    : isEnd
                    ? Colors.red
                    : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isStart
                      ? 'S'
                      : isEnd
                      ? 'E'
                      : '$sequence',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  /// Tính toán zoom level tối ưu
  double _calculateOptimalZoom(LatLngBounds bounds) {
    final latDiff = bounds.north - bounds.south;
    final lngDiff = bounds.east - bounds.west;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff > 1.0) return 8.0;
    if (maxDiff > 0.5) return 10.0;
    if (maxDiff > 0.1) return 12.0;
    return 14.0;
  }

  /// Load địa chỉ cho một scan item
  Future<void> _loadAddressForScan(Map<String, dynamic> scan) async {
    if (scan['latitude'] == null || scan['longitude'] == null) return;

    final lat = scan['latitude'].toString();
    final lng = scan['longitude'].toString();
    final key = '$lat,$lng';

    if (_addresses.containsKey(key)) return;

    try {
      final address = await AddressService.getAddressFromCoordinates(
        double.parse(lat),
        double.parse(lng),
      );
      if (mounted) {
        setState(() {
          _addresses[key] = address ?? 'Unknown location';
        });
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
    }
  }

  /// Load địa chỉ cho tất cả scan items
  Future<void> _loadAllAddresses() async {
    for (final scan in _scanHistory) {
      await _loadAddressForScan(scan);
    }
  }

  /// Lấy HBL để query từ API (không cần HBL cụ thể cho API all-hbl-locations)
  String _getHBLForQuery() {
    print('[HISTORY] _getHBLForQuery() called - using all-hbl-locations API');

    // API all-hbl-locations không cần HBL cụ thể, trả về "ALL" để đánh dấu
    return 'ALL';
  }

  /// Tính tổng khoảng cách của tất cả HBLs
  double _calculateTotalDistance() {
    if (_scanHistory.isEmpty) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _scanHistory.length; i++) {
      final prev = _scanHistory[i - 1];
      final curr = _scanHistory[i];

      if (prev['latitude'] != null &&
          prev['longitude'] != null &&
          curr['latitude'] != null &&
          curr['longitude'] != null) {
        final prevLat = double.parse(prev['latitude'].toString());
        final prevLng = double.parse(prev['longitude'].toString());
        final currLat = double.parse(curr['latitude'].toString());
        final currLng = double.parse(curr['longitude'].toString());

        totalDistance +=
            Geolocator.distanceBetween(prevLat, prevLng, currLat, currLng) /
            1000; // km
      }
    }

    return totalDistance;
  }

  /// Tính thời gian di chuyển
  String _calculateDuration() {
    if (_scanHistory.isEmpty) return '0h';

    final firstTime = DateTime.parse(_scanHistory.first['scannedAt']);
    final lastTime = DateTime.parse(_scanHistory.last['scannedAt']);
    final duration = lastTime.difference(firstTime);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
