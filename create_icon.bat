@echo off
echo Creating app icon from Logo.webp...

REM Get dependencies
flutter pub get

REM Generate launcher icons
flutter pub run flutter_launcher_icons:main

REM Clean and rebuild
flutter clean
flutter pub get

echo Icon generation completed!
echo Please run: flutter run
pause
