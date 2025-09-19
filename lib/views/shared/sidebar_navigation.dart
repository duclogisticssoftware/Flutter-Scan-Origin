import 'package:flutter/material.dart';
import 'package:qrscan_app/views/Scan/scan_screen.dart';
import 'package:qrscan_app/views/History/history_screen.dart';
import 'package:qrscan_app/views/Settings/settings_screen.dart';
import 'package:qrscan_app/views/Test/responsive_test_screen.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

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
    NavigationItem(
      icon: Icons.report,
      title: 'Reports',
      screen: const PlaceholderScreen(title: 'Reports'),
    ),
    NavigationItem(
      icon: Icons.screen_rotation,
      title: 'Responsive Test',
      screen: const ResponsiveTestScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Better breakpoints for macOS and desktop platforms
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    // Additional check for macOS - consider it desktop if width > 1000
    final isMacOSDesktop = screenWidth > 1000 && screenHeight > 600;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _navigationItems[_selectedIndex].title,
          style: TextStyle(fontSize: screenWidth < 360 ? 16 : 20),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: !isTablet && !isMacOSDesktop,
      ),
      drawer: (isDesktop || isMacOSDesktop) ? null : _buildDrawer(),
      body: Row(
        children: [
          // Desktop sidebar
          if (isDesktop || isMacOSDesktop) _buildDesktopSidebar(),

          // Main content
          Expanded(child: _navigationItems[_selectedIndex].screen),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        size: 24,
                        color: ThemeColors.getPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'QR Scan Vinalink',
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
                      color: isSelected
                          ? ThemeColors.getPrimaryColor(context)
                          : ThemeColors.getHintColor(context),
                      size: 22,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? ThemeColors.getPrimaryColor(context)
                            : ThemeColors.getTextColor(context),
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
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Version 1.0.0',
                  style: ThemeColors.getHintStyle(
                    context,
                  ).copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  '© 2024 QR Scan Vinalink',
                  style: ThemeColors.getHintStyle(
                    context,
                  ).copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
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
            height: isSmallScreen ? 160 : 200,
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
                  children: [
                    // Logo
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
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
                        size: isSmallScreen ? 24 : 30,
                        color: ThemeColors.getPrimaryColor(context),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'QR Scan Vinalink',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      'Professional QR Scanner',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
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
                      color: isSelected
                          ? ThemeColors.getPrimaryColor(context)
                          : ThemeColors.getHintColor(context),
                      size: isSmallScreen ? 20 : 24,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? ThemeColors.getPrimaryColor(context)
                            : ThemeColors.getTextColor(context),
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
              },
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
                  style: ThemeColors.getHintStyle(
                    context,
                  ).copyWith(fontSize: isSmallScreen ? 10 : 12),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '© 2024 QR Scan Vinalink',
                  style: ThemeColors.getHintStyle(
                    context,
                  ).copyWith(fontSize: isSmallScreen ? 8 : 10),
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

// Placeholder screen for future navigation items
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
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('$title', style: ThemeColors.getTitleStyle(context)),
            const SizedBox(height: 8),
            Text('Coming Soon', style: ThemeColors.getSubtitleStyle(context)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
