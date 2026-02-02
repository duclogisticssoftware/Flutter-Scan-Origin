# 🚀 QR Scan App - Web Deployment

## Quick Deploy

### Option 1: Use Deployment Scripts
```bash
# Windows Command Prompt
deploy_web.bat

# Windows PowerShell
.\deploy_web.ps1
```

### Option 2: Manual Deploy

#### Firebase Hosting (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy
```

#### Netlify (Drag & Drop)
1. Run: `flutter build web --release`
2. Go to [netlify.com](https://netlify.com)
3. Drag `build/web` folder to deploy area

#### Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Build and deploy
flutter build web --release
cd build/web
vercel --prod
```

## Features
- ✅ QR Code Scanner (Camera)
- ✅ Authentication System
- ✅ Location Tracking
- ✅ History Management
- ✅ PWA Support
- ✅ Responsive Design

## Requirements
- HTTPS (required for camera access)
- Modern browser with camera support
- Flutter 3.9.0+

## Build Size
- ~35MB (includes CanvasKit)
- Optimized with tree-shaking
- Compressed assets

## Support
- Chrome/Edge: Full support
- Firefox: Full support  
- Safari: Full support
- Mobile browsers: Full support

---
**Note**: Camera access requires HTTPS in production. All hosting platforms above provide SSL certificates.

