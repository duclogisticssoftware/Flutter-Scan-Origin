#!/bin/bash
echo "Creating app icon from Logo.webp..."

# Get dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Clean and rebuild
flutter clean
flutter pub get

echo "Icon generation completed!"
echo "Please run: flutter run"
