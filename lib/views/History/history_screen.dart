import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qrscan_app/config/app_config.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qrscan_app/services/address_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AppStorage.instance.read(key: 'jwt');
      final response = await http.get(
        Uri.parse('$apiBase/api/scan/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _scanHistory = data.cast<Map<String, dynamic>>();
        });

        // Load địa chỉ cho tất cả scan items
        _loadAllAddresses();
      } else {
        setState(() {
          _error = 'Failed to load history (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scan History', style: ThemeColors.getTitleStyle(context)),
            const SizedBox(height: 16),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorWidget()
            else if (_scanHistory.isEmpty)
              _buildEmptyWidget()
            else
              Expanded(child: _buildHistoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFD32F2F)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: ThemeColors.getErrorStyle(context).copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Color(0xFF666666)),
          const SizedBox(height: 16),
          Text(
            'No scan history yet',
            style: ThemeColors.getSubtitleStyle(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning QR codes to see your history here',
            style: ThemeColors.getHintStyle(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        itemCount: _scanHistory.length,
        itemBuilder: (context, index) {
          final scan = _scanHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFFFF6B35),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan #${scan['id'] ?? 'Unknown'}',
                              style: ThemeColors.getListItemTitleStyle(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(scan['scannedAt']),
                              style: ThemeColors.getListItemSubtitleStyle(
                                context,
                              ).copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: ThemeColors.getHintColor(context),
                      ),
                    ],
                  ),

                  if (scan['data'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scan['data'],
                        style: ThemeColors.getListItemSubtitleStyle(context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Additional info
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: ThemeColors.getHintColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'User ID: ${scan['userId'] ?? 'Unknown'}',
                        style: ThemeColors.getListItemSubtitleStyle(
                          context,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),

                  // Location info
                  if (scan['latitude'] != null &&
                      scan['longitude'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16,
                          color: ThemeColors.getHintColor(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Location: ${scan['latitude']}, ${scan['longitude']}',
                            style: ThemeColors.getListItemSubtitleStyle(
                              context,
                            ).copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),

                    // Address info
                    if (_getAddressForScan(scan) != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 16,
                            color: ThemeColors.getHintColor(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Tooltip(
                              message: _getAddressForScan(scan)!,
                              child: Text(
                                _getAddressForScan(scan)!,
                                style:
                                    ThemeColors.getListItemSubtitleStyle(
                                      context,
                                    ).copyWith(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Mini map
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () => _showFullScreenMap(
                            context,
                            double.parse(scan['latitude'].toString()),
                            double.parse(scan['longitude'].toString()),
                          ),
                          child: Stack(
                            children: [
                              _MiniLocationMap(
                                latitude: double.parse(
                                  scan['latitude'].toString(),
                                ),
                                longitude: double.parse(
                                  scan['longitude'].toString(),
                                ),
                              ),
                              // Tap indicator
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown time';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showFullScreenMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _FullScreenMap(latitude: latitude, longitude: longitude),
      ),
    );
  }

  /// Load địa chỉ cho một scan item
  Future<void> _loadAddressForScan(Map<String, dynamic> scan) async {
    if (scan['latitude'] == null || scan['longitude'] == null) return;

    final lat = scan['latitude'].toString();
    final lng = scan['longitude'].toString();
    final key = '$lat,$lng';

    // Kiểm tra cache trước
    if (_addresses.containsKey(key)) return;

    try {
      final address = await AddressService.getShortAddress(
        double.parse(lat),
        double.parse(lng),
      );

      if (address != null && mounted) {
        setState(() {
          _addresses[key] = address;
        });
      }
    } catch (e) {
      // Ignore error, sẽ hiển thị tọa độ thay vì địa chỉ
    }
  }

  /// Load địa chỉ cho tất cả scan items
  Future<void> _loadAllAddresses() async {
    for (final scan in _scanHistory) {
      if (scan['latitude'] != null && scan['longitude'] != null) {
        await _loadAddressForScan(scan);
        // Delay nhỏ để tránh spam API
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Lấy địa chỉ từ cache cho một scan item
  String? _getAddressForScan(Map<String, dynamic> scan) {
    if (scan['latitude'] == null || scan['longitude'] == null) return null;

    final lat = scan['latitude'].toString();
    final lng = scan['longitude'].toString();
    final key = '$lat,$lng';

    return _addresses[key];
  }
}

class _MiniLocationMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const _MiniLocationMap({required this.latitude, required this.longitude});

  @override
  State<_MiniLocationMap> createState() => _MiniLocationMapState();
}

class _MiniLocationMapState extends State<_MiniLocationMap> {
  bool _mapError = false;

  @override
  void initState() {
    super.initState();
    // Delay map initialization to avoid mouse tracking issues
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return _buildMapErrorWidget();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FlutterMap(
        options: MapOptions(
          center: LatLng(widget.latitude, widget.longitude),
          zoom: 14.0,
          minZoom: 3.0,
          maxZoom: 18.0,
          interactiveFlags:
              InteractiveFlag.pinchZoom |
              InteractiveFlag.drag, // Chỉ cho phép zoom và drag
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.vinalink.qrscan',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(widget.latitude, widget.longitude),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF6B35),
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Map unavailable',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const _FullScreenMap({required this.latitude, required this.longitude});

  @override
  State<_FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<_FullScreenMap> {
  bool _mapError = false;

  @override
  void initState() {
    super.initState();
    // Delay map initialization to avoid mouse tracking issues
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Map'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _mapError
          ? _buildFullScreenErrorWidget()
          : Container(
              width: double.infinity,
              height: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(widget.latitude, widget.longitude),
                  zoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  interactiveFlags: InteractiveFlag
                      .all, // Full interaction cho full screen map
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vinalink.qrscan',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.latitude, widget.longitude),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF6B35),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFullScreenErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Map unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Google Maps API key not configured',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Coordinates:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
            style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
