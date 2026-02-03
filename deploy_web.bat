@echo off
echo ========================================
echo    LMS General Report - Web Deployment Script
echo ========================================
echo.

:menu
echo Choose deployment method:
echo 1. Firebase Hosting
echo 2. Netlify (Manual)
echo 3. Vercel
echo 4. GitHub Pages
echo 5. Surge.sh
echo 6. Test locally
echo 7. Exit
echo.
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto firebase
if "%choice%"=="2" goto netlify
if "%choice%"=="3" goto vercel
if "%choice%"=="4" goto github
if "%choice%"=="5" goto surge
if "%choice%"=="6" goto test
if "%choice%"=="7" goto exit
goto menu

:firebase
echo.
echo ========================================
echo    Deploying to Firebase Hosting
echo ========================================
echo.

echo Checking Firebase CLI...
firebase --version >nul 2>&1
if errorlevel 1 (
    echo Firebase CLI not found. Installing...
    npm install -g firebase-tools
    if errorlevel 1 (
        echo Failed to install Firebase CLI. Please install Node.js first.
        pause
        goto menu
    )
)

echo Logging in to Firebase...
firebase login
if errorlevel 1 (
    echo Failed to login to Firebase.
    pause
    goto menu
)

echo Initializing Firebase project...
firebase init hosting
if errorlevel 1 (
    echo Failed to initialize Firebase project.
    pause
    goto menu
)

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Deploying to Firebase...
firebase deploy
if errorlevel 1 (
    echo Failed to deploy to Firebase.
    pause
    goto menu
)

echo.
echo ✅ Successfully deployed to Firebase Hosting!
echo Your app is now live at: https://your-project-id.web.app
echo.
pause
goto menu

:netlify
echo.
echo ========================================
echo    Manual Netlify Deployment
echo ========================================
echo.

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Opening build directory...
explorer build\web

echo.
echo 📋 Manual steps for Netlify:
echo 1. Go to https://netlify.com
echo 2. Drag and drop the 'build\web' folder
echo 3. Wait for deployment to complete
echo 4. Configure custom domain if needed
echo.
pause
goto menu

:vercel
echo.
echo ========================================
echo    Deploying to Vercel
echo ========================================
echo.

echo Checking Vercel CLI...
vercel --version >nul 2>&1
if errorlevel 1 (
    echo Vercel CLI not found. Installing...
    npm install -g vercel
    if errorlevel 1 (
        echo Failed to install Vercel CLI. Please install Node.js first.
        pause
        goto menu
    )
)

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Deploying to Vercel...
cd build\web
vercel --prod
cd ..\..

echo.
echo ✅ Successfully deployed to Vercel!
echo.
pause
goto menu

:github
echo.
echo ========================================
echo    Deploying to GitHub Pages
echo ========================================
echo.

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Creating deployment branch...
git checkout -b gh-pages
git add build/web/*
git commit -m "Deploy web app to GitHub Pages"
git push origin gh-pages

echo.
echo 📋 Manual steps for GitHub Pages:
echo 1. Go to your repository on GitHub
echo 2. Go to Settings > Pages
echo 3. Source: Deploy from a branch
echo 4. Branch: gh-pages / folder: / (root)
echo 5. Save and wait for deployment
echo.
pause
goto menu

:surge
echo.
echo ========================================
echo    Deploying to Surge.sh
echo ========================================
echo.

echo Checking Surge CLI...
surge --version >nul 2>&1
if errorlevel 1 (
    echo Surge CLI not found. Installing...
    npm install -g surge
    if errorlevel 1 (
        echo Failed to install Surge CLI. Please install Node.js first.
        pause
        goto menu
    )
)

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Deploying to Surge...
cd build\web
surge
cd ..\..

echo.
echo ✅ Successfully deployed to Surge.sh!
echo.
pause
goto menu

:test
echo.
echo ========================================
echo    Testing Web App Locally
echo ========================================
echo.

echo Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo Failed to build Flutter web app.
    pause
    goto menu
)

echo Starting local server...
echo Your app will be available at: http://localhost:8080
echo Press Ctrl+C to stop the server
echo.

cd build\web
python -m http.server 8080
cd ..\..

pause
goto menu

:exit
echo.
echo Thank you for using LMS General Report deployment script!
echo.
pause
exit

:error
echo.
echo ❌ An error occurred during deployment.
echo Please check the error messages above and try again.
echo.
pause
goto menu

