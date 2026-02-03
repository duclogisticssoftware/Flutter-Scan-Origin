# LMS General Report - Web Deployment Script (PowerShell)
# This script helps deploy your Flutter QR Scan app to various web platforms

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   LMS General Report - Web Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Show-Menu {
    Write-Host "Choose deployment method:" -ForegroundColor Yellow
    Write-Host "1. Firebase Hosting" -ForegroundColor Green
    Write-Host "2. Netlify (Manual)" -ForegroundColor Green
    Write-Host "3. Vercel" -ForegroundColor Green
    Write-Host "4. GitHub Pages" -ForegroundColor Green
    Write-Host "5. Surge.sh" -ForegroundColor Green
    Write-Host "6. Test locally" -ForegroundColor Green
    Write-Host "7. Exit" -ForegroundColor Red
    Write-Host ""
}

function Deploy-Firebase {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Deploying to Firebase Hosting" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check Firebase CLI
    try {
        $firebaseVersion = firebase --version 2>$null
        Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Firebase CLI not found. Installing..." -ForegroundColor Red
        npm install -g firebase-tools
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install Firebase CLI. Please install Node.js first." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }

    # Login to Firebase
    Write-Host "🔐 Logging in to Firebase..." -ForegroundColor Yellow
    firebase login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to login to Firebase." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Initialize Firebase project
    Write-Host "⚙️ Initializing Firebase project..." -ForegroundColor Yellow
    firebase init hosting
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to initialize Firebase project." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Deploy to Firebase
    Write-Host "🚀 Deploying to Firebase..." -ForegroundColor Yellow
    firebase deploy
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to deploy to Firebase." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "✅ Successfully deployed to Firebase Hosting!" -ForegroundColor Green
    Write-Host "Your app is now live at: https://your-project-id.web.app" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Deploy-Netlify {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Manual Netlify Deployment" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Open build directory
    Write-Host "📁 Opening build directory..." -ForegroundColor Yellow
    Start-Process "explorer.exe" -ArgumentList "build\web"

    Write-Host ""
    Write-Host "📋 Manual steps for Netlify:" -ForegroundColor Yellow
    Write-Host "1. Go to https://netlify.com" -ForegroundColor White
    Write-Host "2. Drag and drop the 'build\web' folder" -ForegroundColor White
    Write-Host "3. Wait for deployment to complete" -ForegroundColor White
    Write-Host "4. Configure custom domain if needed" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Deploy-Vercel {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Deploying to Vercel" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check Vercel CLI
    try {
        $vercelVersion = vercel --version 2>$null
        Write-Host "✅ Vercel CLI found: $vercelVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Vercel CLI not found. Installing..." -ForegroundColor Red
        npm install -g vercel
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install Vercel CLI. Please install Node.js first." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Deploy to Vercel
    Write-Host "🚀 Deploying to Vercel..." -ForegroundColor Yellow
    Push-Location "build\web"
    vercel --prod
    Pop-Location

    Write-Host ""
    Write-Host "✅ Successfully deployed to Vercel!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Deploy-GitHubPages {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Deploying to GitHub Pages" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Create deployment branch
    Write-Host "🌿 Creating deployment branch..." -ForegroundColor Yellow
    git checkout -b gh-pages
    git add build/web/*
    git commit -m "Deploy web app to GitHub Pages"
    git push origin gh-pages

    Write-Host ""
    Write-Host "📋 Manual steps for GitHub Pages:" -ForegroundColor Yellow
    Write-Host "1. Go to your repository on GitHub" -ForegroundColor White
    Write-Host "2. Go to Settings > Pages" -ForegroundColor White
    Write-Host "3. Source: Deploy from a branch" -ForegroundColor White
    Write-Host "4. Branch: gh-pages / folder: / (root)" -ForegroundColor White
    Write-Host "5. Save and wait for deployment" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Deploy-Surge {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Deploying to Surge.sh" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check Surge CLI
    try {
        $surgeVersion = surge --version 2>$null
        Write-Host "✅ Surge CLI found: $surgeVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Surge CLI not found. Installing..." -ForegroundColor Red
        npm install -g surge
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install Surge CLI. Please install Node.js first." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    # Deploy to Surge
    Write-Host "🚀 Deploying to Surge..." -ForegroundColor Yellow
    Push-Location "build\web"
    surge
    Pop-Location

    Write-Host ""
    Write-Host "✅ Successfully deployed to Surge.sh!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Test-Local {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Testing Web App Locally" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Build Flutter web app
    Write-Host "🔨 Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build Flutter web app." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host "🌐 Starting local server..." -ForegroundColor Yellow
    Write-Host "Your app will be available at: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""

    Push-Location "build\web"
    python -m http.server 8080
    Pop-Location

    Read-Host "Press Enter to continue"
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-7)"

    switch ($choice) {
        "1" { Deploy-Firebase }
        "2" { Deploy-Netlify }
        "3" { Deploy-Vercel }
        "4" { Deploy-GitHubPages }
        "5" { Deploy-Surge }
        "6" { Test-Local }
        "7" { 
            Write-Host ""
            Write-Host "Thank you for using LMS General Report deployment script!" -ForegroundColor Green
            Write-Host ""
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "7")

Write-Host "Goodbye! 👋" -ForegroundColor Cyan

