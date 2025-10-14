# 🎯 Hướng dẫn tạo icon app từ Logo.webp

## 📋 Các bước thực hiện:

### Bước 1: Chạy lệnh tạo icon
```bash
# Windows
create_icon.bat

# Linux/Mac
chmod +x create_icon.sh
./create_icon.sh

# Hoặc chạy thủ công:
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter clean
flutter pub get
```

### Bước 2: Kiểm tra icon đã được tạo
Sau khi chạy lệnh, kiểm tra các thư mục:

#### Android:
- `android/app/src/main/res/mipmap-hdpi/`
- `android/app/src/main/res/mipmap-mdpi/`
- `android/app/src/main/res/mipmap-xhdpi/`
- `android/app/src/main/res/mipmap-xxhdpi/`
- `android/app/src/main/res/mipmap-xxxhdpi/`

#### iOS:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

#### Windows:
- `windows/runner/resources/app_icon.ico`

#### Web:
- `web/icons/`

### Bước 3: Test icon
```bash
flutter run
```

## 🔧 Nếu vẫn không hiển thị icon:

### Giải pháp 1: Tạo icon PNG thủ công
1. Mở `assets/images/Logo.webp` bằng image editor
2. Xuất ra PNG với kích thước 1024x1024
3. Lưu với tên `app_icon.png`
4. Cập nhật `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
```

### Giải pháp 2: Sử dụng online converter
1. Truy cập: https://convertio.co/webp-png/
2. Upload file `Logo.webp`
3. Download file PNG
4. Đổi tên thành `app_icon.png`
5. Đặt vào `assets/images/`

### Giải pháp 3: Sử dụng Flutter Icon Generator
1. Truy cập: https://appicon.co/
2. Upload file `Logo.webp`
3. Download icon pack
4. Giải nén vào thư mục phù hợp

## ✅ Kiểm tra kết quả:
- Icon hiển thị trên desktop/mobile
- Icon có màu sắc đúng
- Icon không bị mờ hoặc méo
- Icon phù hợp với theme app

## 🚨 Lưu ý quan trọng:
- File Logo.webp phải có kích thước tối thiểu 1024x1024
- Icon phải có nền trong suốt hoặc màu phù hợp
- Sau khi tạo icon, cần clean và rebuild app
- Xóa app cũ trước khi cài app mới
