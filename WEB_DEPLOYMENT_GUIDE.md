# Hướng dẫn Publish Flutter LMS General Report lên Web

## Tổng quan
Ứng dụng QR Scan của bạn đã được build thành công cho web và sẵn sàng để deploy. Thư mục `build/web` chứa tất cả các file cần thiết để chạy trên web.

## Các bước chuẩn bị

### 1. Kiểm tra Build
✅ Build đã hoàn thành thành công
- Thư mục: `build/web/`
- Kích thước: ~35MB (bao gồm CanvasKit)
- Hỗ trợ: Chrome, Edge, Firefox, Safari

### 2. Các tính năng Web được hỗ trợ
- ✅ QR Code Scanner (sử dụng camera)
- ✅ Authentication (login/register)
- ✅ Location tracking
- ✅ History tracking
- ✅ Responsive design
- ✅ PWA (Progressive Web App)

## Các phương thức Deploy

### Phương thức 1: Firebase Hosting (Khuyến nghị)

#### Bước 1: Cài đặt Firebase CLI
```bash
npm install -g firebase-tools
```

#### Bước 2: Login Firebase
```bash
firebase login
```

#### Bước 3: Khởi tạo Firebase project
```bash
firebase init hosting
```
- Chọn project Firebase của bạn
- Chọn `build/web` làm public directory
- Chọn `Yes` cho single-page app
- Chọn `No` cho GitHub integration

#### Bước 4: Deploy
```bash
firebase deploy
```

### Phương thức 2: Netlify

#### Bước 1: Drag & Drop
1. Truy cập [netlify.com](https://netlify.com)
2. Kéo thả thư mục `build/web` vào vùng deploy
3. Ứng dụng sẽ được deploy tự động

#### Bước 2: Cấu hình Custom Domain (tùy chọn)
1. Vào Site settings
2. Domain management
3. Add custom domain

### Phương thức 3: Vercel

#### Bước 1: Cài đặt Vercel CLI
```bash
npm install -g vercel
```

#### Bước 2: Deploy
```bash
cd build/web
vercel --prod
```

### Phương thức 4: GitHub Pages

#### Bước 1: Tạo repository GitHub
```bash
git init
git add build/web/*
git commit -m "Deploy web app"
git remote add origin https://github.com/username/qrscan-web.git
git push -u origin main
```

#### Bước 2: Enable GitHub Pages
1. Vào Settings > Pages
2. Source: Deploy from a branch
3. Branch: main / folder: /build/web

### Phương thức 5: Surge.sh

#### Bước 1: Cài đặt Surge
```bash
npm install -g surge
```

#### Bước 2: Deploy
```bash
cd build/web
surge
```

## Cấu hình Web-specific

### 1. HTTPS Requirements
- Camera API chỉ hoạt động trên HTTPS
- Đảm bảo hosting provider hỗ trợ SSL

### 2. PWA Configuration
File `manifest.json` đã được cấu hình:
```json
{
    "name": "LMS General Report",
    "short_name": "LMS General Report",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#0175C2",
    "theme_color": "#0175C2"
}
```

### 3. Service Worker
File `flutter_service_worker.js` đã được tạo tự động để hỗ trợ offline.

## Tối ưu hóa Performance

### 1. Compression
- Enable gzip compression trên server
- Sử dụng CDN nếu có thể

### 2. Caching
- Static assets có thể cache lâu dài
- API responses cache ngắn hạn

### 3. Bundle Size
- Build hiện tại: ~35MB
- Có thể giảm bằng cách:
  - Sử dụng `--web-renderer html` (nhưng mất một số tính năng)
  - Tree-shaking đã được enable

## Testing Checklist

### Trước khi Deploy
- [ ] Test trên Chrome desktop
- [ ] Test trên Chrome mobile
- [ ] Test camera permissions
- [ ] Test authentication flow
- [ ] Test responsive design

### Sau khi Deploy
- [ ] Test HTTPS
- [ ] Test PWA installation
- [ ] Test offline functionality
- [ ] Test trên các browser khác nhau

## Troubleshooting

### Camera không hoạt động
- Kiểm tra HTTPS
- Kiểm tra permissions
- Test trên localhost trước

### Performance chậm
- Kiểm tra network speed
- Sử dụng CDN
- Enable compression

### Build errors
```bash
flutter clean
flutter pub get
flutter build web --release
```

## Monitoring & Analytics

### 1. Google Analytics
Thêm vào `web/index.html`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 2. Error Tracking
Có thể thêm Sentry hoặc Bugsnag để track errors.

## Security Considerations

### 1. HTTPS Only
- Camera API yêu cầu HTTPS
- Secure cookies cho authentication

### 2. Content Security Policy
Thêm vào `web/index.html`:
```html
<meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https:;">
```

## Backup & Recovery

### 1. Backup Build Files
```bash
tar -czf qrscan-web-backup.tar.gz build/web/
```

### 2. Version Control
- Tag releases trong Git
- Backup database nếu có

## Kết luận

Ứng dụng QR Scan của bạn đã sẵn sàng để deploy lên web. Firebase Hosting là lựa chọn tốt nhất cho Flutter web apps vì:
- Tích hợp tốt với Flutter
- SSL miễn phí
- CDN global
- Dễ dàng CI/CD

Chúc bạn deploy thành công! 🚀

