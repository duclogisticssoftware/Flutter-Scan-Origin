import 'package:flutter/material.dart';
import 'package:qrscan_app/views/Scan/scan_screen.dart';
import 'package:qrscan_app/views/History/history_screen.dart';
import 'package:qrscan_app/views/Inventory/inventory_screen.dart';
import 'package:qrscan_app/views/Settings/settings_screen.dart';
import 'package:qrscan_app/views/Report/report_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFFF8A65), Color(0xFFFFAB91)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              children: [
                // Header section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App logo
                      Container(
                        width: isSmallScreen ? 60 : 80,
                        height: isSmallScreen ? 60 : 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'LMS General Report',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        'Professional QR Scanner',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                // Quick actions grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet || isDesktop ? 3 : 2,
                  crossAxisSpacing: isSmallScreen ? 8 : 12,
                  mainAxisSpacing: isSmallScreen ? 8 : 12,
                  childAspectRatio: isSmallScreen
                      ? 1.3
                      : (isTablet || isDesktop ? 1.2 : 1.1),
                  children: [
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.qr_code_scanner,
                      title: 'Quét QR',
                      subtitle: 'Scan QR Code',
                      color: const Color(0xFF4CAF50),
                      onTap: () =>
                          _navigateToScreen(context, const ScanScreen()),
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View scan history',
                      color: const Color(0xFF2196F3),
                      onTap: () =>
                          _navigateToScreen(context, const HistoryScreen()),
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.report,
                      title: 'Reports',
                      subtitle: 'View Report',
                      color: const Color(0xFF2196F3),
                      onTap: () =>
                          _navigateToScreen(context, const ReportScreen()),
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.inventory_2,
                      title: 'Inventory',
                      subtitle: 'Container Inventory',
                      color: const Color(0xFF009688),
                      onTap: () =>
                          _navigateToScreen(context, const InventoryScreen()),
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Manage application',
                      color: const Color(0xFF9C27B0),
                      onTap: () =>
                          _navigateToScreen(context, const SettingsScreen()),
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildQuickActionCard(
                      context: context,
                      icon: Icons.analytics,
                      title: 'Analytics',
                      subtitle: 'Detailed report',
                      color: const Color(0xFFFF9800),
                      onTap: () => _showComingSoon(context),
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Footer info
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security,
                            size: isSmallScreen ? 16 : 18,
                            color: const Color(0xFF4CAF50),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Text(
                            'High security',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'Version 1.0.0 • © 2024 LMS General Report',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: isSmallScreen ? 120 : 140),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSmallScreen ? 40 : 50,
                height: isSmallScreen ? 40 : 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: isSmallScreen ? 20 : 24, color: color),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tính năng sắp ra mắt'),
        content: const Text(
          'Tính năng này đang được phát triển và sẽ có trong phiên bản tiếp theo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
