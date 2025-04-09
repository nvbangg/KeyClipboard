# KeyClipboard

A Powerful Clipboard to replace Windows Clipboard with convenient Keyboard shortcut!

## Highlighted Features

- **Always On Top**: Keep any window pinned
- **Custom Paste**: Format text your way
- **Multi-Paste**: Paste all or selected items from clipboard
- **Edit & Sort**: Edit and reorder clipboard content
- **Quick Search**: Fast search clipboard content
- **Saved Items**: Quick access saved items with shortcuts
- **Fast Naming**: Paste file names quickly with custom formats, like `CodeLesson_SomeLessonName.cpp`

***Access features fast with keyboard shortcuts***

### Format Options

- **Using beforeLatest_Latest format**: In format specific options
- **Remove accents**
- **Normalize Punctuation Space**
- **Remove Special Characters**
- **Line Break Options**: Trim excess line breaks, Remove all line breaks
- **Text Case Options**: UPPERCASE, lowercase, Title Case, Sentence case
- **Word Separator Options**: Underscore (_), Hyphen (-), Remove all spaces

![image](https://github.com/user-attachments/assets/fe368924-de4b-4295-90bf-f516ab37698c)

![image](https://github.com/user-attachments/assets/8d350a82-7694-4abc-a1d1-a269ec9ed14a)


### Core Shortcuts

- `CapsLock + S`: Show **Settings** popup
- `CapsLock + Tab + S`: **Switch** to the next preset **tab**
- `CapsLock + Shift + S`: **Always on Top** for active Window<br><br>

- `CapsLock + C`: Show **Clipboard** History
- `CapsLock + Tab + C`: Show **Clipboard** Saved
- `CapsLock + Shift + C`: **Clear** clipboard history<br><br>

- `CapsLock + V`: Paste latest clipboard item 
- `CapsLock + B`: Paste **Before** Latest item
- `CapsLock + A`: Paste **All** items <br><br>

- `CapsLock + Shift + V/B/A`: Paste item(s) with Format
- `CapsLock + Ctrl + V/B/A`: Paste item(s) as Original
- `CapsLock + Tab + V/B/A`: Paste item(s) from Saved **Tab**<br><br>

- `CapsLock + F`: Paste Specific **Format**
- `CapsLock + 1-9`: Paste item by position from saved tab

## Installation

### Method 1: Direct Download (Recommended)
1. Download [KeyClipboard.exe](https://github.com/nvbangg/KeyClipboard/releases/latest)
2. Run `KeyClipboard.exe`
3. Look for the app icon in the system tray

### Method 2: Advanced (Using Source Code)
1. Clone this repository:
`git clone https://github.com/nvbangg/KeyClipboard.git`
2. Install environment from [AutoHotkey v2](https://www.autohotkey.com)
3. Run `KeyClipboard.ahk`
4. Look for the app icon in the system tray
  
### Changelog: 
- Thêm tùy chọn sửa được format specific
- Thêm tính năng tùy chọn cấu hình để chỉnh nhanh settings
- Dùng phím tắt CapsLock + Tab + S để chuyển giữa các cấu hình
- Thêm tùy chọn số lượng mục tối đa trong Clipboard
- Sửa lại giao diện tốt hơn
- Thêm hiển thị tên app và cửa sổ được kích hoạt khi bật Always on Top
- Trong contentviewer sẽ dùng phím tắt riêng để chỉnh sửa văn bản
- Sửa lỗi menu chuột phải vị trí không hợp lý khi nhấn ra bên ngoài rồi click lại
- Thêm nếu xóa một mục thì sẽ tự động focus xuống mục cuối cùng (giúp xóa nhanh nhiều mục bằng delete)
- Sửa lỗi thanh tìm kiếm không hoạt động
- Sửa để chỉ sửa được với 1 mục được chọn  
- Sửa một vài lỗi khác
- Có thể dùng phím esc để đóng cửa sổ