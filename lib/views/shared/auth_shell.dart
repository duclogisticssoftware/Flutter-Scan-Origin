import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qrscan_app/config/brand.dart';
import 'package:qrscan_app/utils/theme_colors.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? 24 : 20,
                vertical: isVerySmallScreen ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 600 ? 400 : screenWidth * 0.9,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top spacer to keep content visually centered on tall screens
                      if (constraints.maxHeight > 700)
                        SizedBox(height: (constraints.maxHeight - 700) / 2),

                      const _LogoWidget(path: brandLogoAsset),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.getSurfaceTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),

                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          color: ThemeColors.getSurfaceSecondaryTextColor(
                            context,
                          ),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 40),

                      form,

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final String path;
  const _LogoWidget({required this.path});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 600;
    final logoSize = isVerySmallScreen ? 60.0 : 80.0;

    final lower = path.toLowerCase();
    return lower.endsWith('.svg')
        ? SvgPicture.asset(
            path,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          )
        : Image.asset(
            path,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Icon(
                Icons.business,
                size: logoSize,
                color: const Color(0xFFFF6B35),
              );
            },
          );
  }
}
