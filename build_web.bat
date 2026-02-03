@echo off
echo ========================================
echo    LMS General Report - Web Build & Deploy
echo ========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

echo [1/5] Cleaning previous build...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo [2/5] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo [3/5] Building web app...
flutter build web --release --web-renderer canvaskit
if %errorlevel% neq 0 (
    echo ERROR: Flutter build web failed
    pause
    exit /b 1
)

echo [4/5] Testing API connectivity...
echo Testing API endpoint: https://qr.logisticssoftware.vn/api/health
curl -I https://qr.logisticssoftware.vn/api/health
if %errorlevel% neq 0 (
    echo WARNING: API health check failed - this might cause issues
    echo Please ensure the API server is running and accessible
) else (
    echo SUCCESS: API server is accessible
)

echo [5/5] Build completed successfully!
echo.
echo Build output directory: build\web
echo.
echo Next steps:
echo 1. Test the app locally: flutter run -d chrome
echo 2. Open api_test.html in browser to test API connectivity
echo 3. Deploy to Firebase: firebase deploy
echo 4. Or upload build\web folder to your web hosting
echo.
echo ========================================
echo    Build completed successfully!
echo ========================================
pause
