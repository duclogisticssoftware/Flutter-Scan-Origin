#!/usr/bin/env python3
"""
Script tạo icon mẫu cho LMS General Report
Tạo một icon đơn giản với màu cam Vinalink và biểu tượng QR code
"""

from PIL import Image, ImageDraw, ImageFont
import os


def create_sample_icon():
    """Tạo icon mẫu 1024x1024 với logo QR scanner"""

    # Tạo thư mục nếu chưa có
    os.makedirs("assets/images", exist_ok=True)

    # Kích thước icon
    size = 1024

    # Tạo hình ảnh với nền cam Vinalink
    img = Image.new("RGBA", (size, size), (255, 107, 53, 255))  # #FF6B35
    draw = ImageDraw.Draw(img)

    # Vẽ khung QR code đơn giản
    # Tính toán kích thước QR code
    qr_size = size // 2
    qr_x = (size - qr_size) // 2
    qr_y = (size - qr_size) // 2

    # Vẽ nền trắng cho QR code
    draw.rectangle([qr_x, qr_y, qr_x + qr_size, qr_y + qr_size], fill="white")

    # Vẽ các ô vuông đen để tạo QR code đơn giản
    cell_size = qr_size // 8
    for i in range(8):
        for j in range(8):
            if (i + j) % 2 == 0:  # Tạo pattern QR code đơn giản
                x1 = qr_x + i * cell_size
                y1 = qr_y + j * cell_size
                x2 = x1 + cell_size
                y2 = y1 + cell_size
                draw.rectangle([x1, y1, x2, y2], fill="black")

    # Vẽ viền cho QR code
    draw.rectangle(
        [qr_x, qr_y, qr_x + qr_size, qr_y + qr_size], outline="black", width=4
    )

    # Thêm text "QR" ở góc
    try:
        # Thử sử dụng font mặc định
        font_size = size // 8
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # Nếu không có font, sử dụng font mặc định
        font = ImageFont.load_default()

    text = "QR"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]

    text_x = size - text_width - 20
    text_y = size - text_height - 20

    # Vẽ nền trắng cho text
    draw.rectangle(
        [text_x - 10, text_y - 10, text_x + text_width + 10, text_y + text_height + 10],
        fill="white",
    )
    draw.text((text_x, text_y), text, fill="black", font=font)

    # Lưu file
    output_path = "assets/images/Logo.png"
    img.save(output_path, "PNG")
    print(f"✅ Đã tạo icon mẫu: {output_path}")
    print(f"📏 Kích thước: {size}x{size} pixels")
    print(f"🎨 Màu chủ đạo: #FF6B35 (cam Vinalink)")

    return output_path


if __name__ == "__main__":
    try:
        create_sample_icon()
        print("\n🚀 Bây giờ bạn có thể chạy:")
        print("   flutter pub get")
        print("   flutter pub run flutter_launcher_icons:main")
        print("   flutter clean")
        print("   flutter pub get")
        print("   flutter run")
    except ImportError:
        print("❌ Cần cài đặt Pillow:")
        print("   pip install Pillow")
    except Exception as e:
        print(f"❌ Lỗi: {e}")
