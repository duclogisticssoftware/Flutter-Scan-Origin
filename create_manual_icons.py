#!/usr/bin/env python3
"""
Script tạo icon thủ công cho Android từ file logovnl.png
Tạo các kích thước icon cần thiết cho Android
"""

from PIL import Image
import os

def create_android_icons():
    """Tạo các icon Android với kích thước khác nhau"""
    
    # Đường dẫn file gốc
    source_path = "assets/images/logovnl.png"
    
    # Kiểm tra file gốc có tồn tại không
    if not os.path.exists(source_path):
        print(f"❌ Không tìm thấy file: {source_path}")
        return False
    
    # Các kích thước icon cần thiết cho Android
    icon_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    print("🎨 Đang tạo icon Android...")
    
    # Mở file gốc
    try:
        original_image = Image.open(source_path)
        print(f"✅ Đã mở file gốc: {source_path}")
        print(f"📏 Kích thước gốc: {original_image.size}")
    except Exception as e:
        print(f"❌ Lỗi mở file: {e}")
        return False
    
    # Tạo icon cho từng kích thước
    for folder, size in icon_sizes.items():
        try:
            # Tạo thư mục nếu chưa có
            folder_path = f"android/app/src/main/res/{folder}"
            os.makedirs(folder_path, exist_ok=True)
            
            # Resize ảnh
            resized_image = original_image.resize((size, size), Image.Resampling.LANCZOS)
            
            # Lưu file
            output_path = f"{folder_path}/ic_launcher.png"
            resized_image.save(output_path, "PNG")
            
            print(f"✅ Đã tạo: {output_path} ({size}x{size})")
            
        except Exception as e:
            print(f"❌ Lỗi tạo icon {folder}: {e}")
            return False
    
    print("\n🎉 Hoàn thành tạo icon Android!")
    print("📱 Các file icon đã được tạo trong:")
    for folder in icon_sizes.keys():
        print(f"   - android/app/src/main/res/{folder}/ic_launcher.png")
    
    return True

def create_ios_icons():
    """Tạo các icon iOS với kích thước khác nhau"""
    
    source_path = "assets/images/logovnl.png"
    
    if not os.path.exists(source_path):
        print(f"❌ Không tìm thấy file: {source_path}")
        return False
    
    # Các kích thước icon cần thiết cho iOS
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024
    }
    
    print("\n🍎 Đang tạo icon iOS...")
    
    try:
        original_image = Image.open(source_path)
    except Exception as e:
        print(f"❌ Lỗi mở file: {e}")
        return False
    
    # Tạo thư mục iOS
    ios_folder = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_folder, exist_ok=True)
    
    # Tạo icon cho từng kích thước
    for filename, size in ios_sizes.items():
        try:
            # Resize ảnh
            resized_image = original_image.resize((size, size), Image.Resampling.LANCZOS)
            
            # Lưu file
            output_path = f"{ios_folder}/{filename}"
            resized_image.save(output_path, "PNG")
            
            print(f"✅ Đã tạo: {filename} ({size}x{size})")
            
        except Exception as e:
            print(f"❌ Lỗi tạo icon {filename}: {e}")
            return False
    
    print("\n🎉 Hoàn thành tạo icon iOS!")
    print("🍎 Các file icon đã được tạo trong:")
    print(f"   - {ios_folder}/")
    
    return True

if __name__ == "__main__":
    print("🚀 Bắt đầu tạo icon thủ công...")
    
    # Tạo icon Android
    android_success = create_android_icons()
    
    # Tạo icon iOS
    ios_success = create_ios_icons()
    
    if android_success and ios_success:
        print("\n✅ Hoàn thành tạo tất cả icon!")
        print("\n📋 Bước tiếp theo:")
        print("1. flutter clean")
        print("2. flutter pub get")
        print("3. flutter run")
    else:
        print("\n❌ Có lỗi trong quá trình tạo icon")
