# KeyClipboard

An advanced clipboard manager and keyboard automation tool with flexible shortcuts and powerful features.

## Features

### Clipboard Management
- **Smart Clipboard History**: Access and manipulate your clipboard history with ease
- **Formatted Pasting**: Apply various text formatting options when pasting
- **Multi-item Operations**: Paste multiple clipboard items at once with custom formatting
- **Content Editing**: Edit clipboard items directly within the history viewer
- **Item Organization**: Rearrange clipboard items with keyboard shortcuts

### Keyboard Enhancements
- **Quick Translation**: Instantly translate web pages in Chrome
- **Mouse Emulation**: Control mouse clicks with keyboard shortcuts
- **NumLock Control**: Option to keep NumLock always enabled

## Keyboard Shortcuts

### Core Shortcuts
- `CapsLock+C`: Open clipboard history viewer
- `CapsLock+V`: Paste latest clipboard item
- `CapsLock+B`: Paste the item before the latest
- `CapsLock+A`: Paste all clipboard items consecutively
- `CapsLock+F`: Paste with formatting options
- `CapsLock+D`: Paste all items with formatting
- `CapsLock+X`: Clear clipboard history
- `CapsLock+S`: Open settings window
- `CapsLock+T`: Translate current page in Chrome

### Clipboard History Viewer Shortcuts
- `Double-click`: Paste selected item
- `Enter`: Paste selected items
- `Alt+↑`: Move selected item up in the list
- `Alt+↓`: Move selected item down in the list
- `Ctrl+Click`: Select multiple individual items
- `Shift+Click`: Select a range of items
- `Right-click`: Open context menu with more options

### Mouse Mode
- `Right Alt`: Left mouse click
- `Right Ctrl`: Right mouse click

## Formatting Options

- **Text Case Conversion**
  - UPPERCASE
  - lowercase
  - Title Case
  
- **Character Processing**
  - Remove diacritics (accent marks)
  - Remove line breaks
  
- **Word Separators**
  - Underscore (_)
  - Hyphen (-)
  - No spaces

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

### Tính năng dự kiến
- Giữ nguyên các định dạng (in đậm, nghiêng,...) của nội dung khi sao chép
- Thêm tuỳ chọn xoá định dạng (in đậm, ...)
- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

### Changelog:
- Sửa một số lỗi và ổn định các tính năng
- Thêm tính năng có thể thêm nội dung được định dạng vào clipboard
- Thêm Có thể dùng Alt+ Up/Down Arrow để thay đổi vị trí của 1 mục
- Thêm các mục trong format options như xoá xuống dòng, đồng thời tách xoá dấu câu thành định dạng riêng
