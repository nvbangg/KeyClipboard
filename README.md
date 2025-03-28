# KeyClipboard

A Powerful Clipboard to replace Windows Clipboard with convenient Keyboard shortcut!

## Highlighted Features

- **Always on Top**: Pin a window to stay on top with a shortcut
- **Formatted Paste**: Paste text with your custom format
- **Multi-Item Paste**: Paste all or selected items from your clipboard
- **Edit & Rearrange**: Easily edit content and move items in the clipboard.
- **Quick Search**: Fast search clipboard content.
- **Saved Items**: Access saved items fast with shortcuts

### Format Options

- **Remove accents**
- **Normalize Punctuation Space**
- **Remove Special Characters**
- **Line Break Options**: Trim excess line breaks, Remove all line breaks
- **Text Case Options**: UPPERCASE, lowercase, Title Case, Sentence case
- **Word Separator Options**: Underscore (_), Hyphen (-), Remove all spaces

![image](https://github.com/user-attachments/assets/fa99ecbc-4470-43d0-83a2-3c3e1140990b)


![image](https://github.com/user-attachments/assets/bdf16447-be3b-4a04-a751-eb5c5654ea3a)



### Core Shortcuts
- `CapsLock + S`: Show **Settings** popup
- `CapsLock + Shift + S`: **Always on Top** for active Window
- `CapsLock + C`: Show **Clipboard** History
- `CapsLock + Tab + C`: Show **Clipboard** Saved
- `CapsLock + Shift + C`: **Clear** clipboard history
- `CapsLock + F`: Specific **Format** (Paste combining previous and current items) 

- `CapsLock + V`: Paste latest clipboard item 
- `CapsLock + B`: Paste **Before** Latest item
- `CapsLock + A`: Paste **All** items 
- `CapsLock + Shift + V/B/A`: Paste item(s) with Format
- `CapsLock + Ctrl + V/B/A`: Paste item(s) as Original
- `CapsLock + Tab + V/B/A`: Paste item(s) from Saved tab
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
- Xoá chức năng translate in chrome, always enable numlock, mouse click mode
- Các chức năng trên chuyển sang dự án khác
- Sửa đổi cấu trúc dự án và tối ưu code
- Hướng dẫn sử dụng cho lần đầu cài app
- Sửa lỗi không focus vào mục cuối cùng khi mở clipboard
- Thêm thông báo xác nhận trước khi Clear All trong Saved tab
- Sửa lại phím tắt:
- `CapsLock + Shift + S`: **Always on Top** for active Window
- `CapsLock + Tab + C`: Show **Clipboard** Saved
- `CapsLock + Shift + C`: **Clear** clipboard history
- `CapsLock + Shift + V/B/A`: Paste item(s) with Format
- `CapsLock + Ctrl + V/B/A`: Paste item(s) as Original
- `CapsLock + Tab + V/B/A`: Paste item(s) from Saved tab
