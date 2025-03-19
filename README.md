# KeyClipboard

Powerful Clipboard manager and Keyboard automation tool with flexible Shortcuts

## Highlighted Features

- **Always on Top**: Pin a window to stay on top with a shortcut
- **Formatted Pasting**: Paste items with custom text formatting
- **Multi-Item Paste**: Paste multiple clipboard items at once
- **Edit Content**: Edit items directly in the clipboard history viewer
- **Organize Items**: Adjust the position of items in the clipboard
- **Quick Translation**: Translate Chrome pages instantly with a shortcut

![image](https://github.com/user-attachments/assets/3942361e-097a-422c-a8eb-bd4ca9858678)

## Core Shortcuts
- `CapsLock + S`: Show **Settings** popup
- `CapsLock + W`: Toggle Always-on-Top for active **Window**
- `CapsLock + T`: **Translate** Chrome page
- `CapsLock + V`: Paste latest clipboard item 
- `CapsLock + B`: Paste **Before** Latest item
- `CapsLock + A`: Paste **All** items 
- `CapsLock + Shift + V/B/A`: Paste item(s) with Format
- `CapsLock + Ctrl + V/B/A`: Paste items(s) as Original
- `CapsLock + Space`: Show clipboard history
- `CapsLock + C`: **Clear** clipboard history
- `Alt + ↑/↓`: Move selected item up/down
- `CapsLock + F`: Specific **Format** (Paste combined previous and current items)

## Settings Options
![image](https://github.com/user-attachments/assets/99076f93-7f65-402c-8519-9ffae92476b6)

### Keyboard Options
- Mouse Clicks Mode
  - `Right Alt`: Left mouse click
  - `Right Ctrl`: Right mouse click
- Always Enable NumLock

### Format Options

- **Remove accents**
- **Normalize Punctuation Space**
- **Line Break Options**: Trim excess line breaks, Remove all line breaks
- **Text Case Options**: UPPERCASE, lowercase, Title Case, Sentence case
- **Word Separator Options**: Underscore (_), Hyphen (-), Remove all spaces

## Installation

### Method 1: Direct Download (Recommended)
1. Download [KeyClipboard.exe](https://github.com/nvbangg/KeyClipboard/releases)
2. Run `KeyClipboard.exe`
3. Look for the app icon in the system tray

### Method 2: Advanced (Using Source Code)
1. Install environment from [AutoHotkey v2](https://www.autohotkey.com)
2. Clone this repository:
`git clone https://github.com/nvbangg/KeyClipboard.git`
3. Run `KeyClipboard.ahk`
4. Look for the app icon in the system tray

### Auto-Start with Windows
1. Navigate to: `%appdata%\Microsoft\Windows\Start Menu\Programs\Startup`
2. Create a shortcut to `KeyClipboard.exe` or `KeyClipboard.ahk`
3. Place the shortcut in this folder
4. The application will now start automatically when you boot your computer

## Tính năng dự kiến

- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

### Changelog: 
- Thêm lựa chọn và phím tắt Paste as Original (có in đậm, nghiêng,...)
- Xoá các nút paste all
- Thêm dùng Ctrl A để chọn tất cả, delete để xoá các mục chọn
- Thêm hướng dẫn dùng clipboard
- Sửa phím tắt tách biệt chức năng khi chọn muc/ chọn nội dung
- Sửa lỗi khi dùng chức năng Save format to Clipboard
- Sửa một vài vấn đề khác