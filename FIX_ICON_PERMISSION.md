# 🔧 Hướng dẫn sửa lỗi quyền truy cập khi tạo icon

## 🚨 Vấn đề hiện tại:
- Lỗi "Permission denied" khi tạo icon
- Không thể ghi file vào thư mục Android/iOS
- Cần quyền administrator để tạo icon

## 🚀 Giải pháp:

### Cách 1: Chạy PowerShell với quyền Administrator

1. **Đóng PowerShell hiện tại**
2. **Mở PowerShell với quyền Administrator:**
   - Nhấn `Windows + X`
   - Chọn "Windows PowerShell (Admin)" hoặc "Terminal (Admin)"
   - Nhấn "Yes" khi được hỏi quyền

3. **Chuyển đến thư mục project:**
   ```powershell
   cd C:\Users\PCPV\qrscan_app
   ```

4. **Chạy script tạo icon:**
   ```powershell
   python create_manual_icons.py
   ```

### Cách 2: Sử dụng Command Prompt với quyền Administrator

1. **Mở Command Prompt với quyền Administrator:**
   - Nhấn `Windows + R`
   - Gõ `cmd`
   - Nhấn `Ctrl + Shift + Enter`

2. **Chuyển đến thư mục project:**
   ```cmd
   cd C:\Users\PCPV\qrscan_app
   ```

3. **Chạy script:**
   ```cmd
   python create_manual_icons.py
   ```

### Cách 3: Sử dụng flutter_launcher_icons với quyền Administrator

1. **Mở PowerShell với quyền Administrator**
2. **Chuyển đến thư mục project:**
   ```powershell
   cd C:\Users\PCPV\qrscan_app
   ```

3. **Chạy lệnh tạo icon:**
   ```powershell
   flutter pub get
   dart run flutter_launcher_icons:main
   ```

### Cách 4: Tạo icon thủ công (không cần quyền đặc biệt)

1. **Mở file `assets/images/logovnl.png` bằng image editor**
2. **Tạo các kích thước icon cần thiết:**

#### Android Icons:
- **48x48** → `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- **72x72** → `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- **96x96** → `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- **144x144** → `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- **192x192** → `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

#### iOS Icons:
- **20x20** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- **40x40** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- **60x60** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- **29x29** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- **58x58** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- **87x87** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- **40x40** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- **80x80** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- **120x120** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- **120x120** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- **180x180** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- **76x76** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- **152x152** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- **167x167** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- **1024x1024** → `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`

### Cách 5: Sử dụng online icon generator

1. **Truy cập:** https://appicon.co/
2. **Upload file:** `assets/images/logovnl.png`
3. **Download icon pack**
4. **Giải nén và copy vào thư mục tương ứng**

## ✅ Kiểm tra kết quả:

Sau khi tạo icon, kiểm tra:

### Android:
```powershell
dir android\app\src\main\res\mipmap-*\ic_launcher.png
```

### iOS:
```powershell
dir ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-*.png
```

## 🚀 Test app:

```powershell
flutter clean
flutter pub get
flutter run
```

## 🚨 Lưu ý quan trọng:

1. **Luôn chạy với quyền Administrator** khi tạo icon
2. **Đóng tất cả editor/IDE** trước khi tạo icon
3. **Xóa app cũ** trước khi cài app mới
4. **Kiểm tra icon trên thiết bị thật**, không chỉ emulator

## 🔧 Nếu vẫn không được:

1. **Restart máy tính**
2. **Chạy PowerShell với quyền Administrator**
3. **Kiểm tra antivirus** có block không
4. **Sử dụng Command Prompt** thay vì PowerShell
5. **Tạo icon thủ công** bằng image editor
