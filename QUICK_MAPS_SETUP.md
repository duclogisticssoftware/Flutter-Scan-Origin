# Quick Google Maps Setup

## Lỗi hiện tại: "Cannot read properties of undefined (reading 'maps')"

Lỗi này xảy ra vì Google Maps API key chưa được cấu hình.

## Giải pháp nhanh:

### 1. Lấy Google Maps API Key:
1. Truy cập: https://console.cloud.google.com/
2. Tạo project mới hoặc chọn project hiện có
3. Vào **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **API Key**
5. Copy API key

### 2. Cấu hình trong app:
Mở file `android/app/src/main/AndroidManifest.xml` và thay thế:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

Thành:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" />
```

### 3. Restart app:
```bash
flutter clean
flutter pub get
flutter run
```

## Tạm thời:
App sẽ hiển thị fallback UI với tọa độ text thay vì map khi API key chưa có.

## Bảo mật (Khuyến nghị):
- Không commit API key vào Git
- Sử dụng environment variables
- Giới hạn API key theo package name và SHA-1
