import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static bool isMacOSDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 1000 && size.height > 600;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 700;
  }

  static bool isVerySmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context) || isMacOSDesktop(context)) {
      return const EdgeInsets.all(24);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else if (isSmallScreen(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) || isMacOSDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) || isMacOSDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) || isMacOSDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Check if should show desktop layout
  static bool shouldShowDesktopLayout(BuildContext context) {
    return isDesktop(context) || isMacOSDesktop(context);
  }

  // Check if should show mobile layout
  static bool shouldShowMobileLayout(BuildContext context) {
    return isMobile(context);
  }

  // Get responsive constraints for content
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (isDesktop(context) || isMacOSDesktop(context)) {
      return BoxConstraints(maxWidth: width * 0.8, minWidth: 600);
    } else if (isTablet(context)) {
      return BoxConstraints(maxWidth: width * 0.9, minWidth: 400);
    } else {
      return BoxConstraints(maxWidth: width * 0.95, minWidth: 300);
    }
  }
}
