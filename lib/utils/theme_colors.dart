import 'package:flutter/material.dart';

class ThemeColors {
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onBackground;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onBackground.withOpacity(0.6);
  }

  static Color getSurfaceTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getSurfaceSecondaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getErrorBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.error.withOpacity(0.1);
  }

  static Color getErrorBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.error.withOpacity(0.3);
  }

  static Color getHintColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline.withOpacity(0.2);
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  // Text styles with theme colors
  static TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: getTextColor(context),
    );
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    return TextStyle(fontSize: 16, color: getSecondaryTextColor(context));
  }

  static TextStyle getLabelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: getSurfaceTextColor(context),
    );
  }

  static TextStyle getHintStyle(BuildContext context) {
    return TextStyle(fontSize: 14, color: getHintColor(context));
  }

  static TextStyle getErrorStyle(BuildContext context) {
    return TextStyle(fontSize: 14, color: getErrorColor(context));
  }

  static TextStyle getTextStyle(BuildContext context) {
    return TextStyle(fontSize: 16, color: getSurfaceTextColor(context));
  }

  static TextStyle getCardTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: getSurfaceTextColor(context),
    );
  }

  static TextStyle getCardSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: getSurfaceSecondaryTextColor(context),
    );
  }

  static TextStyle getListItemTitleStyle(BuildContext context) {
    return TextStyle(fontSize: 16, color: getSurfaceTextColor(context));
  }

  static TextStyle getListItemSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: getSurfaceSecondaryTextColor(context),
    );
  }
}
