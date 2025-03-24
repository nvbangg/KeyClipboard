# KeyClipboard

Powerful Clipboard manager and Keyboard automation tool with flexible Shortcuts

## Highlighted Features

- **Always on Top**: Pin a window to stay on top with a shortcut
- **Formatted Pasting**: Paste items with custom text formatting
- **Multi-Item Paste**: Paste all clipboard items or selected items
- **Edit Content**: Edit items directly in the clipboard history viewer
- **Organize Items**: Adjust the position of items in the clipboard
- **Quick Search**: Rapidly search through clipboard content.
- **Quick Translation**: Translate Chrome pages  instantly with a shortcut
- **Saved Items Access**: Quickly access saved items with dedicated shortcuts

![image](https://github.com/user-attachments/assets/09264c1a-a0ea-460e-adea-750caefd8fe6)


## Core Shortcuts
- `CapsLock + S`: Show **Settings** popup
- `CapsLock + T`: **Translate** Chrome page
- `CapsLock + Space + T`: **Always on Top** for active Window
- `CapsLock + C`: Show **Clipboard** History
- `CapsLock + Space + C`: **Clear** clipboard history
- `CapsLock + F`: Specific **Format** (Paste combining previous and current items) 

- `CapsLock + V`: Paste latest clipboard item 
- `CapsLock + B`: Paste **Before** Latest item
- `CapsLock + A`: Paste **All** items 
- `CapsLock + Space + V/B/A`: Paste item(s) with Format
- `CapsLock + Shift + V/B/A`: Paste item(s) as Original
- `CapsLock + Ctrl + V/B/A`: Paste item(s) from Saved tab
- `CapsLock + 1-9`: Paste item by position from saved tab

## Settings Options
![image](https://github.com/user-attachments/assets/31e67eeb-3424-45af-b28d-768b80af151d)


### Keyboard Options
- Mouse Clicks Mode
  - `Right Alt`: Left mouse click
  - `Right Ctrl`: Right mouse click
- Always Enable NumLock

### Format Options

- **Remove accents**
- **Normalize Punctuation Space**
- **Remove Special Characters**
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

- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá
    
### Changelog: 
- Sửa đổi cấu trúc dự án
- Thêm tab Saved để lưu nội dung được lưu và hoạt động độc lập
- Nội dung được saved tab được lưu vào file mà không bị mất
- Thêm phím tắt CapsLock + 1-9 để dán nhanh mục theo vị trí trong saved tab
- Thêm phím tắt CapsLock + Ctrl + V/B/A để dán nội dung từ saved tab

