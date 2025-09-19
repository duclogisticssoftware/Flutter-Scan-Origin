import 'package:flutter/material.dart';
import 'package:qrscan_app/services/theme_service.dart';
import 'package:qrscan_app/services/auth_service.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Clear stored token using AuthService
      await AuthService.logout();

      // Navigate back to login screen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 768;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 12 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: ThemeColors.getTitleStyle(
              context,
            ).copyWith(fontSize: isSmallScreen ? 20 : 24),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),

          // User info card
          Card(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: ThemeColors.getCardTitleStyle(
                      context,
                    ).copyWith(fontSize: isSmallScreen ? 16 : 18),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Manage your account settings',
                    style: ThemeColors.getCardSubtitleStyle(
                      context,
                    ).copyWith(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Settings options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: const Color(0xFFFF6B35),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  title: Text(
                    'Profile',
                    style: ThemeColors.getListItemTitleStyle(
                      context,
                    ).copyWith(fontSize: isSmallScreen ? 14 : 16),
                  ),
                  subtitle: Text(
                    'Edit your profile information',
                    style: ThemeColors.getListItemSubtitleStyle(
                      context,
                    ).copyWith(fontSize: isSmallScreen ? 12 : 14),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: isSmallScreen ? 14 : 16,
                    color: ThemeColors.getHintColor(context),
                  ),
                  onTap: () {
                    // TODO: Navigate to profile screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile feature coming soon',
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.notifications,
                    color: Color(0xFFFF6B35),
                  ),
                  title: Text(
                    'Notifications',
                    style: ThemeColors.getListItemTitleStyle(context),
                  ),
                  subtitle: Text(
                    'Manage notification preferences',
                    style: ThemeColors.getListItemSubtitleStyle(context),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ThemeColors.getHintColor(context),
                  ),
                  onTap: () {
                    // TODO: Navigate to notifications settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications feature coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: const Color(0xFFFF6B35),
                  ),
                  title: Text(
                    'Theme',
                    style: ThemeColors.getListItemTitleStyle(context),
                  ),
                  subtitle: Text(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'Dark Mode'
                        : 'Light Mode',
                    style: ThemeColors.getListItemSubtitleStyle(context),
                  ),
                  trailing: Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return Switch(
                        value: Theme.of(context).brightness == Brightness.dark,
                        onChanged: (value) async {
                          await ThemeService.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security, color: Color(0xFFFF6B35)),
                  title: Text(
                    'Security',
                    style: ThemeColors.getListItemTitleStyle(context),
                  ),
                  subtitle: Text(
                    'Change password and security settings',
                    style: ThemeColors.getListItemSubtitleStyle(context),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ThemeColors.getHintColor(context),
                  ),
                  onTap: () {
                    // TODO: Navigate to security settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Security feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Logout button
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: Icon(Icons.logout, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Logout',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 16,
                horizontal: isSmallScreen ? 16 : 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
