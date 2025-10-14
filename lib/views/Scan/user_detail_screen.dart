import 'package:flutter/material.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hblData;
  final Map<String, dynamic>? scanInfo;

  const UserDetailScreen({super.key, required this.hblData, this.scanInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HBL Information'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HBL info card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // HBL Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // HBL Number
                    Text(
                      'HBL: ${hblData['hblInfo']?['hblNo'] ?? 'Unknown'}',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 8),

                    // Job Number
                    Text(
                      'Job: ${hblData['jobInfo']?['jobNo'] ?? 'Unknown'}',
                      style: ThemeColors.getTitleStyle(
                        context,
                      ).copyWith(color: const Color(0xFFFF6B35), fontSize: 18),
                    ),
                    const SizedBox(height: 8),

                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Text(
                        'Status: ${hblData['hblInfo']?['statusHBL'] ?? 'Unknown'}',
                        style: ThemeColors.getTitleStyle(context).copyWith(
                          color: const Color(0xFF4CAF50),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // HBL Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HBL Details',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.business,
                      label: 'Shipper',
                      value: hblData['hblInfo']?['shipper'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.person,
                      label: 'Consignee',
                      value: hblData['hblInfo']?['consignee'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'POL',
                      value: hblData['hblInfo']?['polname'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'POD',
                      value: hblData['hblInfo']?['podname'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'ETD',
                      value: hblData['hblInfo']?['ETD'] != null
                          ? DateTime.parse(
                              hblData['hblInfo']['ETD'],
                            ).toString().split(' ')[0]
                          : 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'ETA',
                      value: hblData['hblInfo']?['ETA'] != null
                          ? DateTime.parse(
                              hblData['hblInfo']['ETA'],
                            ).toString().split(' ')[0]
                          : 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional HBL Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.inventory,
                      label: 'Packages',
                      value: hblData['hblInfo']?['packages'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.scale,
                      label: 'Weight',
                      value: hblData['hblInfo']?['weight'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.crop_free,
                      label: 'Volume',
                      value: hblData['hblInfo']?['volume'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.attach_money,
                      label: 'Freight',
                      value: hblData['hblInfo']?['freight'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.notifications,
                      label: 'Notify',
                      value: hblData['hblInfo']?['notify'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.description,
                      label: 'Description',
                      value: hblData['hblInfo']?['description'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // MBL Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MBL Details',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.local_shipping,
                      label: 'MBL',
                      value: hblData['mblInfo']?['mbl'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.directions_boat,
                      label: 'Vessel',
                      value: hblData['mblInfo']?['vessel'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.route,
                      label: 'Voyage',
                      value: hblData['mblInfo']?['voy'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Job Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Details',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.work,
                      label: 'Job No',
                      value: hblData['jobInfo']?['jobNo'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.category,
                      label: 'Type',
                      value: hblData['jobInfo']?['loai'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.info,
                      label: 'Status',
                      value: hblData['jobInfo']?['statusJob'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scan info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Information',
                      style: ThemeColors.getCardTitleStyle(context),
                    ),
                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.qr_code_scanner,
                      label: 'Scanned At',
                      value: scanInfo?['scannedAt'] != null
                          ? DateTime.parse(
                              scanInfo!['scannedAt'],
                            ).toString().split('.')[0]
                          : DateTime.now().toString().split('.')[0],
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.check_circle,
                      label: 'Status',
                      value: hblData['message'] ?? 'Successfully scanned',
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.input,
                      label: 'Input Type',
                      value: hblData['inputType'] ?? 'QR_SCAN',
                    ),

                    if (scanInfo?['latitude'] != null &&
                        scanInfo?['longitude'] != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.my_location,
                        label: 'Coordinates',
                        value:
                            '${scanInfo!['latitude']}, ${scanInfo!['longitude']}',
                      ),
                      const SizedBox(height: 16),
                      // Map section
                      Text(
                        'Location Map',
                        style: ThemeColors.getCardTitleStyle(context),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _LocationMap(
                            latitude: double.parse(
                              scanInfo!['latitude'].toString(),
                            ),
                            longitude: double.parse(
                              scanInfo!['longitude'].toString(),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (scanInfo?['address'] != null &&
                        scanInfo!['address'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.place,
                        label: 'Address',
                        value: scanInfo!['address'],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add more actions
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF666666),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF6B35)),
        const SizedBox(width: 12),
        Text('$label: ', style: ThemeColors.getLabelStyle(context)),
        Expanded(
          child: Tooltip(
            message: value,
            child: Text(
              value,
              style: ThemeColors.getListItemTitleStyle(context),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const _LocationMap({required this.latitude, required this.longitude});

  @override
  State<_LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<_LocationMap> {
  bool _mapError = false;

  @override
  void initState() {
    super.initState();
    // Delay map initialization to avoid mouse tracking issues
    Future.delayed(const Duration(milliseconds: 500), () {
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

    try {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(widget.latitude, widget.longitude),
            zoom: 15.0,
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
      );
    } catch (e) {
      // Nếu có lỗi, hiển thị fallback
      return _buildMapErrorWidget();
    }
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
              '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
