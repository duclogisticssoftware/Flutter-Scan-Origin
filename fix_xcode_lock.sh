#!/bin/bash

echo "🔧 Khắc phục lỗi Xcode database locked"
echo "======================================"

echo "1. Dừng tất cả Xcode processes..."
sudo pkill -f Xcode 2>/dev/null || true
sudo pkill -f xcodebuild 2>/dev/null || true
sudo pkill -f Simulator 2>/dev/null || true

echo "2. Xóa Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true

echo "3. Clean Flutter project..."
flutter clean
flutter pub get

echo "4. Clean iOS project..."
cd ios
rm -rf build/ 2>/dev/null || true
rm -rf Pods/ 2>/dev/null || true
rm -rf Podfile.lock 2>/dev/null || true
pod install --repo-update
cd ..

echo "5. Reset iOS Simulator..."
xcrun simctl shutdown all 2>/dev/null || true
xcrun simctl erase all 2>/dev/null || true

echo "6. Mở Simulator..."
open -a Simulator

echo "7. Chạy Flutter app..."
flutter run -d "iPhone 16 Pro Max"

echo "✅ Hoàn thành!"
