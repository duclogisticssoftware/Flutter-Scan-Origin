# Google Maps Setup Guide

## Cách lấy Google Maps API Key

### Bước 1: Tạo Google Cloud Project
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Kích hoạt Google Maps API

### Bước 2: Tạo API Key
1. Vào **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **API Key**
3. Copy API key được tạo

### Bước 3: Cấu hình API Key trong app
1. Mở file `android/app/src/main/AndroidManifest.xml`
2. Tìm dòng:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY" />
   ```
3. Thay `YOUR_GOOGLE_MAPS_API_KEY` bằng API key thực tế

### Bước 4: Bảo mật API Key (Khuyến nghị)
1. Tạo file `android/app/src/debug/res/values/strings.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="google_maps_key">YOUR_DEBUG_API_KEY</string>
   </resources>
   ```

2. Tạo file `android/app/src/release/res/values/strings.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="google_maps_key">YOUR_RELEASE_API_KEY</string>
   </resources>
   ```

3. Cập nhật `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="@string/google_maps_key" />
   ```

### Bước 5: Giới hạn API Key
1. Vào **APIs & Services** > **Credentials**
2. Click vào API key
3. Trong **Application restrictions**, chọn **Android apps**
4. Thêm package name: `com.vinalink.qrscan`
5. Thêm SHA-1 fingerprint của app

### Lấy SHA-1 Fingerprint:
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (nếu có)
keytool -list -v -keystore path/to/your/release.keystore -alias your_alias
```

## Tính năng Map
- Hiển thị vị trí scan trên Google Maps
- Marker với tọa độ chính xác
- Zoom controls để phóng to/thu nhỏ
- Info window hiển thị tọa độ chi tiết

## Lưu ý
- API key cần được bảo mật, không commit vào Git
- Có thể sử dụng environment variables hoặc build flavors
- Test trên thiết bị thật để đảm bảo map hoạt động đúng
