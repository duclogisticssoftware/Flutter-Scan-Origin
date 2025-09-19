import 'package:flutter/material.dart';
import 'package:qrscan_app/views/Scan/scan_screen.dart';
import 'package:qrscan_app/views/History/history_screen.dart';
import 'package:qrscan_app/views/Settings/settings_screen.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_navigationItems[_selectedIndex].title),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _navigationItems[_selectedIndex].screen,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header with logo and app name
          Container(
            height: 200,
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
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 30,
                        color: ThemeColors.getPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Scan Vinalink',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'QR Scan Vinalink',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
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
                      size: 24,
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
                        fontSize: 16,
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
                  ).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2024 QR Scan Vinalink',
                  style: ThemeColors.getHintStyle(
                    context,
                  ).copyWith(fontSize: 10),
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
