# QuickKit

QuickKit là công cụ tăng năng suất được phát triển bằng AutoHotkey, giúp người dùng làm việc hiệu quả hơn trên Windows.

## Tính năng chính

- **Quản lý Clipboard**: Lưu trữ và quản lý lịch sử clipboard, cho phép dễ dàng truy cập lại nội dung đã sao chép trước đó.
- **Khởi động nhanh ứng dụng**: Mở nhanh các ứng dụng thường dùng thông qua menu hoặc phím tắt.
- **Điều khiển chuột bằng bàn phím**: Cho phép di chuyển chuột và thực hiện các thao tác click bằng bàn phím.
- **Phím tắt tùy chỉnh**: Thiết lập các phím tắt riêng cho các chức năng thường dùng.

## Cài đặt

1. Tải xuống phiên bản mới nhất từ trang phát hành.
2. Giải nén vào thư mục bất kỳ trên máy tính.
3. Chạy file `QuickKit.ahk` để khởi động ứng dụng.
4. (Tùy chọn) Tạo shortcut tới file này trong thư mục Startup để tự động chạy khi khởi động Windows.

## Phím tắt mặc định

- **Ctrl+Shift+C**: Mở menu nhanh
- **Ctrl+Shift+V**: Mở quản lý clipboard
- **Ctrl+Shift+M**: Bật/tắt chế độ điều khiển chuột

### Phím tắt trong chế độ điều khiển chuột:

- **I**: Di chuyển chuột lên
- **K**: Di chuyển chuột xuống
- **J**: Di chuyển chuột sang trái
- **L**: Di chuyển chuột sang phải
- **U**: Click chuột trái
- **O**: Click chuột phải
- **Space**: Tắt chế độ điều khiển chuột

## Tùy chỉnh

Bạn có thể thay đổi các cài đặt thông qua:
- Menu cài đặt trong ứng dụng
- Chỉnh sửa trực tiếp file `settings.ini`

## Cấu trúc thư mục

```
QuickKit/
├── modules/           # Các module chức năng
│   ├── Apps.ahk
│   ├── Clipboard.ahk
│   └── MouseAndKey.ahk
├── core/              # Các thành phần cốt lõi của ứng dụng
│   ├── UI.ahk         # Xử lý giao diện người dùng
│   └── Common.ahk     # Các hàm tiện ích chung
├── settings.ini       # File cài đặt
├── icon.ico           # Icon của ứng dụng
├── QuickKit.ahk       # File chính
└── README.md          # Tài liệu hướng dẫn cơ bản
```

## Yêu cầu hệ thống

- Windows 7/8/10/11
- AutoHotkey v1.1 hoặc cao hơn (nếu chạy từ mã nguồn)
