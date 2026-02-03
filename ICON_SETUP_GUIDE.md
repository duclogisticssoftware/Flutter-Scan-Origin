# 🎯 Hướng dẫn thiết lập icon cho LMS General Report

## 📋 Vấn đề hiện tại:
- App chưa có icon hiển thị trên điện thoại
- File `assets/images/Logo.webp` không tồn tại
- Cần tạo icon từ file logo

## 🚀 Giải pháp:

### Bước 1: Tạo file logo/icon
Bạn cần có một file logo với các yêu cầu sau:
- **Định dạng**: PNG hoặc WEBP
- **Kích thước**: Tối thiểu 1024x1024 pixels
- **Nội dung**: Logo của Vinalink hoặc QR scanner
- **Màu sắc**: Phù hợp với theme app (#FF6B35)

#### Cách tạo logo:
1. **Sử dụng thiết kế có sẵn**: Nếu bạn có logo Vinalink, resize về 1024x1024
2. **Tạo logo mới**: Sử dụng Canva, Figma, hoặc Photoshop
3. **Sử dụng AI**: Dùng ChatGPT, DALL-E để tạo logo QR scanner

### Bước 2: Đặt file logo vào đúng vị trí
```bash
# Tạo thư mục nếu chưa có
mkdir -p assets/images

# Đặt file logo vào thư mục (đổi tên thành Logo.webp hoặc Logo.png)
# Ví dụ: Logo.png -> assets/images/Logo.png
```

### Bước 3: Cập nhật cấu hình pubspec.yaml
Nếu sử dụng file PNG thay vì WEBP:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  web: true
  windows: true
  macos: true
  image_path: "assets/images/Logo.png"  # Đổi từ .webp thành .png
  min_sdk_android: 21
  remove_alpha_ios: true
```

### Bước 4: Chạy lệnh tạo icon
```bash
# Windows
create_icon.bat

# Hoặc chạy thủ công:
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter clean
flutter pub get
```

### Bước 5: Kiểm tra kết quả
Sau khi chạy lệnh, kiểm tra các thư mục:

#### Android:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

#### iOS:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Bước 6: Test app
```bash
flutter run
```

## 🔧 Nếu vẫn không hiển thị icon:

### Giải pháp 1: Tạo icon PNG thủ công
1. Tạo file PNG 1024x1024 với logo của bạn
2. Lưu với tên `app_icon.png` trong `assets/images/`
3. Cập nhật `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
```

### Giải pháp 2: Sử dụng online icon generator
1. Truy cập: https://appicon.co/
2. Upload file logo của bạn
3. Download icon pack
4. Giải nén vào thư mục phù hợp

### Giải pháp 3: Sử dụng Flutter Icon Generator
1. Truy cập: https://icon.kitchen/
2. Upload file logo
3. Download các kích thước icon cần thiết
4. Đặt vào thư mục tương ứng

## 📱 Yêu cầu kỹ thuật:

### Android:
- **Mipmap-hdpi**: 72x72px
- **Mipmap-mdpi**: 48x48px  
- **Mipmap-xhdpi**: 96x96px
- **Mipmap-xxhdpi**: 144x144px
- **Mipmap-xxxhdpi**: 192x192px

### iOS:
- **App Icon 20pt**: 20x20, 40x40, 60x60
- **App Icon 29pt**: 29x29, 58x58, 87x87
- **App Icon 40pt**: 40x40, 80x80, 120x120
- **App Icon 60pt**: 60x60, 120x120, 180x180
- **App Icon 76pt**: 76x76, 152x152
- **App Icon 83.5pt**: 167x167
- **App Icon 1024pt**: 1024x1024

## ✅ Kiểm tra kết quả:
- [ ] Icon hiển thị trên desktop/mobile
- [ ] Icon có màu sắc đúng
- [ ] Icon không bị mờ hoặc méo
- [ ] Icon phù hợp với theme app
- [ ] Icon hiển thị trên tất cả platform (Android, iOS, Web, Windows, macOS)

## 🚨 Lưu ý quan trọng:
- File logo phải có kích thước tối thiểu 1024x1024
- Icon phải có nền trong suốt hoặc màu phù hợp
- Sau khi tạo icon, cần clean và rebuild app
- Xóa app cũ trước khi cài app mới
- Kiểm tra icon trên thiết bị thật, không chỉ emulator

## 🎨 Gợi ý thiết kế icon:
- **Màu chủ đạo**: #FF6B35 (cam Vinalink)
- **Biểu tượng**: QR code, scanner, hoặc logo Vinalink
- **Style**: Modern, clean, dễ nhận biết
- **Tỷ lệ**: Vuông, không bị méo
- **Độ phân giải**: Cao, sắc nét
