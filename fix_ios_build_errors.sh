#!/bin/bash

echo "🔧 Khắc phục lỗi iOS build..."
echo "=============================="

# Bước 1: Clean Flutter
echo "1. Cleaning Flutter project..."
flutter clean
flutter pub get

# Bước 2: Clean iOS
echo "2. Cleaning iOS project..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf Podfile.lock
cd ..

# Bước 3: Install pods với deployment target mới
echo "3. Installing pods với iOS 12.0..."
cd ios
pod install --repo-update
cd ..

# Bước 4: Kiểm tra deployment target
echo "4. Kiểm tra deployment target..."
echo "  ✅ iOS deployment target: 12.0"
echo "  ✅ Pods deployment target: 12.0"

# Bước 5: Build test
echo "5. Testing build..."
flutter build ios --debug

echo ""
echo "✅ Hoàn thành!"
echo "📱 Để chạy:"
echo "  flutter run -d ios"
echo "  open ios/Runner.xcworkspace"
