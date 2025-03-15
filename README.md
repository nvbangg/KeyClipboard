# KeyClipboard

An advanced clipboard manager and keyboard automation tool with flexible shortcuts and powerful features.

## Features

### Clipboard Management

- **Always on Top for active window**
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
- `CapsLock+Q`: Toggle Always-on-Top for active window
- `CapsLock+C`: Open clipboard history viewer
- `CapsLock+V`: Paste latest clipboard item
- `CapsLock+B`: Paste the item before the latest
- `CapsLock+A`: Paste all clipboard items consecutively
- `CapsLock+F`: Paste with formatting options
- `CapsLock+D`: Paste all items with formatting
- `CapsLock+X`: Clear clipboard history
- `CapsLock+S`: Open settings window
- `CapsLock+R`: Toggle beforeLatest_Latest feature
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

- Paste with beforeLatest_Latest (toggle with CapsLock+R)
- Remove diacritics
- Fix spacing around punctuation

- **Line Break Handling**
  - None (preserve line breaks)
  - Remove excessive line breaks (no empty lines)
  - Remove all line breaks

- **Text Case Conversion**
  - UPPERCASE
  - lowercase
  - Title Case
  - Sentence case
  
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

## Tính năng dự kiến
- Giữ nguyên các định dạng (in đậm, nghiêng,...) của nội dung khi sao chép
- Thêm tuỳ chọn xoá định dạng (in đậm, ...)
- Có thể ghim các nội dung Clipboard và không bị mất dù khởi động lại
- Có thể dùng các phím tắt để dán nhanh các nội dung được lưu sẵn
- Có thể tự cấu hình phím tắt để mở nhanh app, thư mục, file
- Có thể ghi lại macro (các thao tác chuột, bàn phím) và phát lại tự động hoá

### Changelog:
- Dùng menu thả lên để chọn mục từ settings
- Sửa lỗi Mục About không hiển thị lên đầu khi nhấn từ Settings