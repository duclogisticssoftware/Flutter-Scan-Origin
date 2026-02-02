# 🔧 Troubleshooting Guide - API Issues trên Web

## Vấn đề: App chạy local OK nhưng không gọi được API khi publish lên web

### ✅ **Đã khắc phục:**

1. **CORS Configuration** - API server đã cấu hình CORS với `AllowAll` policy
2. **HTTP Headers** - Đã thêm headers cần thiết cho web requests
3. **Error Handling** - Đã cải thiện error handling cho web environment
4. **HTTPS Support** - API server hỗ trợ HTTPS

### 🔍 **Các bước kiểm tra:**

#### **Bước 1: Test API từ browser**
```bash
# Mở file api_test.html trong browser để test
# Hoặc test trực tiếp từ browser console:
fetch('https://qr.logisticssoftware.vn/api/health')
  .then(response => response.text())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

#### **Bước 2: Kiểm tra Network tab trong DevTools**
1. Mở Chrome DevTools (F12)
2. Vào tab Network
3. Thử login/scan QR
4. Xem các request có thành công không
5. Kiểm tra status code và response

#### **Bước 3: Kiểm tra Console errors**
1. Mở Chrome DevTools (F12)
2. Vào tab Console
3. Tìm các lỗi CORS, network, hoặc JavaScript errors

### 🚨 **Các lỗi thường gặp và cách khắc phục:**

#### **1. CORS Error**
```
Access to fetch at 'https://qr.logisticssoftware.vn/api/auth/login' 
from origin 'https://your-domain.com' has been blocked by CORS policy
```

**Khắc phục:**
- Đảm bảo API server có CORS policy cho phép origin của web app
- Kiểm tra cấu hình CORS trên API server

#### **2. Mixed Content Error**
```
Mixed Content: The page at 'https://your-domain.com' was loaded over HTTPS, 
but requested an insecure resource 'http://qr.logisticssoftware.vn/api/health'
```

**Khắc phục:**
- Đảm bảo API server sử dụng HTTPS
- Kiểm tra URL trong `app_config.dart`

#### **3. SSL Certificate Error**
```
net::ERR_CERT_AUTHORITY_INVALID
```

**Khắc phục:**
- Kiểm tra SSL certificate của API server
- Đảm bảo certificate hợp lệ và không hết hạn

#### **4. Network Timeout**
```
net::ERR_TIMED_OUT
```

**Khắc phục:**
- Kiểm tra kết nối internet
- Tăng timeout trong code
- Kiểm tra API server có đang hoạt động không

### 🛠️ **Các file đã được cập nhật:**

1. **lib/services/auth_service.dart** - Thêm headers cho web
2. **lib/views/Auth/login_screen.dart** - Cải thiện headers
3. **lib/views/Auth/register_screen.dart** - Cải thiện headers
4. **lib/views/Scan/scan_screen.dart** - Cải thiện headers
5. **lib/services/location_tracking_service.dart** - Cải thiện headers
6. **lib/services/http_service.dart** - Service mới cho HTTP requests
7. **lib/config/web_config.dart** - Cấu hình web-specific
8. **firebase.json** - Cấu hình hosting với security headers
9. **api_test.html** - Tool test API từ browser
10. **build_web.bat** - Script build và test

### 📋 **Checklist trước khi deploy:**

- [ ] API server đang chạy và accessible
- [ ] CORS policy đã được cấu hình đúng
- [ ] SSL certificate hợp lệ
- [ ] Test API từ browser thành công
- [ ] Build web app thành công
- [ ] Test app trên localhost trước khi deploy

### 🔧 **Debug commands:**

```bash
# Test API health
curl -I https://qr.logisticssoftware.vn/api/health

# Test CORS
curl -H "Origin: https://your-domain.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://qr.logisticssoftware.vn/api/auth/login

# Build và test local
flutter build web --release
flutter run -d chrome
```

### 📞 **Nếu vẫn có vấn đề:**

1. **Kiểm tra API server logs** - Xem có request nào đến không
2. **Test từ Postman/Insomnia** - Đảm bảo API hoạt động
3. **Kiểm tra firewall/proxy** - Có thể block requests
4. **Test trên browser khác** - Chrome, Firefox, Edge
5. **Kiểm tra network tab** - Xem request có được gửi không

### 🎯 **Kết quả mong đợi:**

Sau khi áp dụng các fix này, app web sẽ:
- ✅ Gọi API thành công từ browser
- ✅ Login/Register hoạt động bình thường
- ✅ Scan QR và gửi location thành công
- ✅ Không có CORS errors
- ✅ Error handling tốt hơn

---

**Lưu ý:** Nếu vẫn có vấn đề, hãy check:
1. API server có đang chạy không
2. Domain web app có được add vào CORS policy không
3. SSL certificate có hợp lệ không
4. Network có stable không
