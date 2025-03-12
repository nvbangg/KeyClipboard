# KeyClipboard

Advanced Clipboard Manager + Tự động hóa thao tác bằng phím tắt linh hoạt với nhiều tính năng hữu ích

## Features and Shortcuts

- **Clipboard Manager**:
    - Paste the item **before** the latest (CapsLock+B) 
    - Paste latest item from clipboard history (CapsLock+V)
    - ***Paste all clipboard items*** (CapsLock+A)
    - Paste all items with format (CapsLock+D)
    - ***Paste latest item with format*** (CapsLock+F)
        1. beforeLatest_Latest: Dán nội dung trước của gần nhất_nội dung gần nhất 
            (phù hợp cho đặt tên file, folder)
        2. Dán theo kiểu: IN HOA, in thường, in không dấu, In Hoa Chữ Cái Đầu
        3. Chọn phân cách: Gạch dưới(_), Gạch ngang(-), Xoá khoảng cách
    - Clear clipboard history (CapsLock+X)
    - Show Settings Popup (CapsLock+S)
    - Show Clipboard History (CapsLock+C)
        - Chế độ xem lịch sử có thể sắp xếp, ***chỉnh sửa nội dung trực tiếp***
        - Dán toàn bộ clipboard hoặc dán nhiều mục được chọn ***theo thứ tự, định dạng tuỳ chỉnh***
        - *Lưu ý: Double click hoặc enter để dán mục đã chọn*
- **Keyboard Settings**:
    - **Chuyển đổi dịch** nhanh chóng trong chrome (CapsLock+T)
    - MouseMode: Right Alt to Click/ Right Ctrl to Right Click
    - Luôn bật phím Numlock 
 
### Tính năng dự kiến
- Có thể chỉnh sửa đồng thời nhiều lựa chọn
- Có thể thêm và điều chỉnh thủ công thứ tự của nội dung trong clipboard
- Giữ nguyên các định dạng (in đậm, nghiêng,...) của nội dung khi sao chép
- Thêm tuỳ chọn xoá định dạng (in đậm, ...)
- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

### Changelog:
- Thêm tính năng có thể thêm nội dung được định dạng vào clipboard


## How to Install

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
