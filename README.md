# KeyClipboard

An advanced clipboard manager and keyboard automation tool with flexible shortcuts and powerful features.

## Features

### Clipboard Management
- **Always on Top**: Quickly toggle window pinning for any application with a single shortcut
- **Formatted Pasting**: Apply various text formatting options when pasting content
- **Multi-item Operations**: Paste multiple clipboard items at once with custom formatting
- **Content Editing**: Edit clipboard items directly within the history viewer
- **Item Organization**: Rearrange clipboard history items 

### Keyboard Enhancements
- **Quick Translation**: Instantly translate web pages in Chrome
- **Mouse Emulation**: Control mouse clicks using keyboard shortcuts (RAlt/RCtrl)
- **NumLock Control**: Option to keep NumLock always enabled

## Keyboard Shortcuts

### Core Shortcuts
- `CapsLock+W`: Toggle Always-on-Top for active window
- `CapsLock+Space`: Open clipboard history viewer
- `CapsLock+V`: Paste latest clipboard item
- `CapsLock+Shift+V`: Paste latest item with text formatting
- `CapsLock+B`: Paste the item before the latest
- `CapsLock+Shift+B`: Paste the item before the latest with text formatting
- `CapsLock+F`: Paste combining previous and current items (with accents removed)
- `CapsLock+A`: Paste all clipboard items
- `CapsLock+Shift+A`: Paste all items with text formatting
- `CapsLock+C`: Clear clipboard history
- `CapsLock+S`: Open settings window
- `CapsLock+T`: Translate current page in Chrome (Chrome only)

### Clipboard History Viewer Shortcuts
- `Double-click`: Paste selected item
- `Enter`: Paste selected items
- `Alt+↑/↓`: Move selected item up/down in the list
- `Ctrl+Click`: Select multiple individual items
- `Shift+Click`: Select a range of items
- `Right-click`: Open context menu with more options

### Mouse Mode
- `Right Alt`: Left mouse click
- `Right Ctrl`: Right mouse click

## Formatting Options

- **Character Handling**
  - Remove accents (diacritical marks)
  - Normalize spaces around punctuation

- **Line Break Handling**
  - None: Preserve line breaks
  - Trim lines: Remove excessive line breaks
  - Remove all: Convert all line breaks to spaces

- **Text Case Conversion**
  - None: Keep original case
  - UPPERCASE: Convert all text to uppercase
  - lowercase: Convert all text to lowercase
  - Title Case: Capitalize First Letter Of Each Word
  - Sentence case: Capitalize first letter of each sentence

- **Word Se parators**
  - None: Keep spaces as-is
  - Underscore (_): Replace spaces with underscores
  - Hyphen (-): Replace spaces with hyphens
  - No spaces: Remove all spaces

## Installation

### Method 1: Direct Download
1. Download [KeyClipboard.exe](https://github.com/nvbangg/KeyClipboard/releases/latest)
2. Run the downloaded file
3. Look for the app icon in the system tray

### Method 2: From Source
1. Install [AutoHotkey v2](https://www.autohotkey.com)
2. Clone this repository
3. Run KeyClipboard.ahk

### Auto-Start with Windows
1. Navigate to: `%appdata%\Microsoft\Windows\Start Menu\Programs\Startup`
2. Create a shortcut to KeyClipboard.exe or KeyClipboard.ahk
3. Place the shortcut in this folder
4. The application will now start automatically when you boot your computer

## Tính năng dự kiến

- Sửa luôn hiển thị mục cuối cùng từ cliboard
- Giữ nguyên các định dạng (in đậm, nghiêng,...) của nội dung khi sao chép
- Thêm tuỳ chọn xoá định dạng (in đậm, ...)
- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

### Changelog: 
- Xoá lựa chọn beforeLatest_Latest trong tuỳ chỉnh định dạng (dùng Capslock+F để thay thế)
- Sửa để luôn removeAccents khi nhấn Capslock+F
- Sửa lỗi chức năng normSpace không xoá khoảng trắng đầu dòng 2 trở đi
- Sửa lại giao diện cho dễ dùng