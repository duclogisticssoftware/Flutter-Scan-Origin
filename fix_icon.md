# Hướng dẫn sửa icon app

## Vấn đề:
- App mất icon sau khi cài đặt
- File Logo.webp có thể không tương thích với flutter_launcher_icons

## Giải pháp:

### Bước 1: Chuyển đổi Logo.webp thành PNG
1. Mở file `assets/images/Logo.webp` bằng image editor (Photoshop, GIMP, hoặc online)
2. Xuất ra file PNG với kích thước 1024x1024 pixels
3. Lưu với tên `app_icon.png` trong thư mục `assets/images/`

### Bước 2: Chạy lệnh tạo icon
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### Bước 3: Clean và rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Bước 4: Kiểm tra icon
- Android: Kiểm tra trong `android/app/src/main/res/`
- iOS: Kiểm tra trong `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Lưu ý:
- Icon phải có kích thước tối thiểu 1024x1024 pixels
- Format PNG được khuyến nghị
- Màu nền nên là màu chủ đạo của app (#FF6B35)
