#!/bin/bash

echo "🔧 Debug iOS App - Khắc phục màn hình trắng"
echo "=============================================="

echo "1. Clean Flutter project..."
flutter clean

echo "2. Get dependencies..."
flutter pub get

echo "3. Clean iOS build..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf Podfile.lock
cd ..

echo "4. Install iOS pods..."
cd ios
pod install --repo-update
cd ..

echo "5. Build iOS app..."
flutter build ios --debug

echo "6. Run on iOS simulator..."
flutter run -d ios

echo "✅ Debug complete!"
echo ""
echo "📱 Nếu vẫn bị màn hình trắng, hãy:"
echo "1. Mở Xcode"
echo "2. Chọn Product > Clean Build Folder"
echo "3. Chạy lại: flutter run -d ios"
echo ""
echo "🔍 Để xem logs chi tiết:"
echo "flutter logs -d ios"
