# KeyClipboard

Keyboard + Clipboard manager với nhiều tính năng hữu ích, tăng năng suất làm việc

## Tính năng và Phím tắt

- ***CapsLock+S để mở settings tuỳ chọn các chế độ***
- **Clipboard Manager**:
    - Capslock+A: **<span style="color: red;">Dán toàn bộ clipboard</span>**
    - Capslock+C: Clear toàn bộ clipboard
    - CapsLock+Z: Dán nội dung clipboard trước của trước đó
    - CapsLock+F: **Dán với định dạng** tuỳ chỉnh
        1. Prefix_text: Dán nội dung trước của trước_nội dung trước
        2. **Dán theo kiểu**: IN HOA, in thường, in không dấu, In Hoa Chữ Cái Đầu
        3. **Chọn phân cách**: Gạch dưới(_), Gạch ngang(-), Xoá khoảng cách
    - CapsLock+V (giống Win+V): Mở Clipboard History
        - Chế độ xem lịch sử có thể sắp xếp, chỉnh sửa tuỳ chỉnh
        - Dán toàn bộ clipboard **theo thứ tự, định dạng tuỳ chỉnh**
        - **Dán nhiều mục được chọn** theo thứ tự, định dạng tuỳ chỉnh
        - *Lưu ý: Double click hoặc enter để dán mục đã chọn*
- **Keyboard Settings** (tuỳ chọn):
    - RAlt/RCtrl: Để click chuột trái/phải
    - Luôn bật phím Numlock
- **Tiện ích Chrome**: 
    - CapsLock+T: Để **chuyển đổi dịch** trang web nhanh chóng
 
### Tính năng dự kiến
- Có thể Thêm nội dung và chỉnh sửa nội dung trực tiếp
- Có thể điều chỉnh thủ công thứ tự của nội dung trong clipboard
- Giữ nguyên các định dạng (in đậm, nghiêng,...) của nội dung khi sao chép
- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

## Cài đặt

### Cách 1. Tải xuống trực tiếp

- Tải [KeyClipboard.exe](https://github.com/nvbangg/KeyClipboard/releases/latest)
- Chạy file sau khi tải xuống
- Kiểm tra app ở khay icons
    
### Cách 2. Tải toàn bộ repository

- Yêu cầu [Autohotkey v2](https://www.autohotkey.com)
- Clone repository và chạy file KeyClipboard.ahk

### Bật tự động khởi chạy khi mở máy tính

 - Vào thư mục `%appdata%\Microsoft\Windows\Start Menu\Programs\Startup`
 - Tạo shortcut của file KeyClipboard.exe hoặc KeyClipboard.ahk và đặt vào thư mục này
 - Ứng dụng sẽ tự động khởi chạy khi mở máy tính

