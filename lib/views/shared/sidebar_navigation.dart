import 'package:flutter/material.dart';
import 'package:qrscan_app/views/Welcome/welcome_screen.dart';
import 'package:qrscan_app/views/Scan/scan_screen.dart';
import 'package:qrscan_app/views/History/history_screen.dart';
import 'package:qrscan_app/views/Settings/settings_screen.dart';
import 'package:qrscan_app/views/shared/tracking_status_widget.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:qrscan_app/views/Report/report_screen.dart';
import 'package:qrscan_app/views/Inventory/inventory_screen.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({super.key});

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      title: 'Home',
      screen: const WelcomeScreen(),
    ),
    NavigationItem(
      icon: Icons.qr_code_scanner,
      title: 'Scan',
      screen: const ScanScreen(),
    ),
    NavigationItem(
      icon: Icons.history,
      title: 'History',
      screen: const HistoryScreen(),
    ),
    NavigationItem(
      icon: Icons.assessment,
      title: 'Report',
      screen: const ReportScreen(),
    ),
    NavigationItem(
      icon: Icons.inventory,
      title: 'Inventory',
      screen: const InventoryScreen(),
    ),
    NavigationItem(
      icon: Icons.settings,
      title: 'Settings',
      screen: const SettingsScreen(),
    ),
    // Future navigation items can be added here
    NavigationItem(
      icon: Icons.analytics,
      title: 'Analytics',
      screen: const PlaceholderScreen(title: 'Analytics'),
    ),
    NavigationItem(
      icon: Icons.people,
      title: 'Users',
      screen: const PlaceholderScreen(title: 'Users'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
              ),
            ),
            child: Column(
              children: [
                // Header with logo and app name
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 24,
                          color: ThemeColors.getPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'LMS APP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Professional QR Scanner',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B35).withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 24,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.transparent,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2026 LMS APP',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Tracking status widget
                const TrackingStatusWidget(),
                // Main content
                Expanded(child: _navigationItems[_selectedIndex].screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
              ),
            ),
            child: Column(
              children: [
                // Header with logo and app name
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 22,
                          color: ThemeColors.getPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LMS APP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Professional QR Scanner',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B35).withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 22,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.transparent,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '© 2026 LMS APP',
                        style: TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Tracking status widget
                const TrackingStatusWidget(),
                // Main content
                Expanded(child: _navigationItems[_selectedIndex].screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('LMS APP'),
        backgroundColor: ThemeColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Tracking status widget
          const TrackingStatusWidget(),
          // Main content
          Expanded(child: _navigationItems[_selectedIndex].screen),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Drawer(
      child: Column(
        children: [
          // Header with logo and app name
          Container(
            height: isSmallScreen ? 140 : 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: isSmallScreen ? 40 : 50,
                      height: isSmallScreen ? 40 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: isSmallScreen ? 20 : 24,
                        color: ThemeColors.getPrimaryColor(context),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Text(
                      'LMS APP',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      'Professional QR Scanner',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(_navigationItems.length, (index) {
                  final item = _navigationItems[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B35).withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? ThemeColors.getPrimaryColor(context)
                            : Colors.grey[600],
                        size: isSmallScreen ? 20 : 24,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected
                              ? ThemeColors.getPrimaryColor(context)
                              : Colors.grey[800],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        Navigator.of(context).pop(); // Close drawer
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '© 2026 LMS APP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 9 : 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String title;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.title,
    required this.screen,
  });
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
