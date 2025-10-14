import 'package:flutter/material.dart';
import 'package:qrscan_app/services/location_tracking_service.dart';

class TrackingStatusWidget extends StatefulWidget {
  const TrackingStatusWidget({super.key});

  @override
  State<TrackingStatusWidget> createState() => _TrackingStatusWidgetState();
}

class _TrackingStatusWidgetState extends State<TrackingStatusWidget> {
  final LocationTrackingService _trackingService = LocationTrackingService();
  bool _isTracking = false;
  String? _currentHBL;

  @override
  void initState() {
    super.initState();
    _updateTrackingStatus();

    // Lắng nghe thay đổi trạng thái tracking
    _trackingService.onTrackingStateChanged = () {
      if (mounted) {
        _updateTrackingStatus();
      }
    };
  }

  @override
  void dispose() {
    _trackingService.onTrackingStateChanged = null;
    super.dispose();
  }

  void _updateTrackingStatus() {
    setState(() {
      _isTracking = _trackingService.isTracking;
      _currentHBL = _trackingService.currentHBL;
    });
  }

  Future<void> _stopTracking() async {
    await _trackingService.stopTracking();
    _updateTrackingStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking stopped'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTracking) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Location Tracking Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                if (_currentHBL != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'HBL: $_currentHBL',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  'Position is being tracked and sent to server',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _stopTracking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Stop', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
