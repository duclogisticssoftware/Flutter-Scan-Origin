# Script to manually create app icons
Write-Host "Creating app icons manually..."

# Create Android icon directories
$androidDirs = @(
    "android\app\src\main\res\mipmap-hdpi",
    "android\app\src\main\res\mipmap-mdpi", 
    "android\app\src\main\res\mipmap-xhdpi",
    "android\app\src\main\res\mipmap-xxhdpi",
    "android\app\src\main\res\mipmap-xxxhdpi"
)

foreach ($dir in $androidDirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir"
    }
}

# Copy Logo.webp to each directory with appropriate names
$sourceFile = "assets\images\Logo.webp"

if (Test-Path $sourceFile) {
    Write-Host "Source file found: $sourceFile"
    
    # Copy to each mipmap directory
    foreach ($dir in $androidDirs) {
        $destFile = Join-Path $dir "ic_launcher.png"
        Copy-Item $sourceFile $destFile -Force
        Write-Host "Copied to: $destFile"
    }
} else {
    Write-Host "Source file not found: $sourceFile"
}

Write-Host "Icon creation completed!"
