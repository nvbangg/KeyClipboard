; KeyClipboard - Powerful Clipboard manager and Keyboard automation tool with flexible Shortcuts

#SingleInstance Force
#Include "modules\Common.ahk"
#Include "modules\Clip.ahk"
#Include "modules\Key.ahk"

; === HOTKEYS ===

#HotIf mouseEnabled
RAlt:: Click()           ; Right Alt to left click
RCtrl:: Click("Right")   ; Right Ctrl to right click
#HotIf

#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: translateInChrome()
#HotIf

CapsLock & s:: showSettings()
CapsLock & f:: pasteSpecific() ; Paste combining previous and current item

#HotIf GetKeyState("CapsLock", "P")
Space & t:: alwaysOnTop() ; Toggle Always-on-Top for active Window
c:: showClipboard()
Space & c:: clearClipboard()

v:: pastePrev(0)                ; Paste latest item from clipboard history
Space & v:: pastePrev(0, 1)     ; Paste latest item with format
+v:: pastePrev(0, -1)           ; Paste latest item as original
b:: pastePrev(1)                ; Paste the item before the latest
Space & b:: pastePrev(1, 1)     ; Paste the item before the latest with format
+b:: pastePrev(1, -1)           ; Paste the item before the latest as original
a:: pasteSelected()             ; Paste all clipboard items
Space & a:: pasteSelected(, , 1) ; Paste all clipboard items with format
+a:: pasteSelected(, , -1)      ; Paste all clipboard items as original
#HotIf

; CapsLock toggle handling
*CapsLock::
{
    KeyWait "CapsLock"
    if (A_PriorKey = "CapsLock") {
        if GetKeyState("CapsLock", "T")
            SetCapsLockState "AlwaysOff"
        else
            SetCapsLockState "AlwaysOn"
    }
}

; === TRAY MENU & UI ===
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showShortcuts(*) {
    static shortcutsGui := 0

    if IsObject(shortcutsGui) {
        SetTimer(() => CheckGuiOutsideClick(shortcutsGui, false), 0)
        shortcutsGui.Destroy()
        shortcutsGui := 0
    }

    ; Create new GUI
    shortcutsGui := Gui("+AlwaysOnTop +ToolWindow", "Shortcuts - KeyClipboard")
    shortcutsGui.SetFont("s10")

    shortcutsGui.Add("Text", "w375",
        "• CapsLock+S: Show Settings Popup`n" .
        "• CapsLock+T: Translate page in Chrome`n" .
        "• CapsLock+Space+T: Always-on-Top for active Window`n" .
        "• CapsLock+C: Show Clipboard History`n" .
        "• CapsLock+Space+C: Clear Clipboard History`n" .
        "• CapsLock+F: Paste combining previous and current item`n`n" .
        "• CapsLock+V: Paste latest item from clipboard history`n" .
        "• CapsLock+B: Paste the item before the latest`n" .
        "• CapsLock+A: Paste all clipboard items`n" .
        "• CapsLock+Space+V/B/A: Paste item(s) with Format`n" .
        "• CapsLock+Shift+V/B/A: Paste item(s) as Original`n`n"
    )

    ; Show GUI and setup event handlers (button removed)
    shortcutsGui.OnEvent("Escape", (*) => CloseShortcuts())
    shortcutsGui.OnEvent("Close", (*) => CloseShortcuts())
    shortcutsGui.Show()
    WinActivate("ahk_id " . shortcutsGui.Hwnd)
    SetTimer(() => CheckGuiOutsideClick(shortcutsGui, false), 100)

    CloseShortcuts() {
        SetTimer(() => CheckGuiOutsideClick(shortcutsGui, false), 0)
        shortcutsGui.Destroy()
        shortcutsGui := 0  ; Reset after destroying
    }
}

showAbout(*) {
    ; Suspend any active timers that might interfere
    SetTimer(() => CheckGuiOutsideClick(A_Args[1], false), 0)
    settingsHwnd := WinExist("KeyClipboard - Settings")
    shortcutsHwnd := WinExist("Core Shortcuts")

    settingsOnTop := settingsHwnd ? WinGetExStyle(settingsHwnd) & 0x8 : false
    shortcutsOnTop := shortcutsHwnd ? WinGetExStyle(shortcutsHwnd) & 0x8 : false

    ; Temporarily remove always-on-top from all windows
    if (settingsHwnd)
        WinSetAlwaysOnTop(0, "ahk_id " . settingsHwnd)
    if (shortcutsHwnd)
        WinSetAlwaysOnTop(0, "ahk_id " . shortcutsHwnd)

    Sleep(50)
    result := MsgBox(
        "KeyClipboard`n" .
        "Version: 1.5.4.2`n" .
        "Date: 19/03/2025`n`n" .
        "Source: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open",
        "About KeyClipboard",
        "YesNo 262144"  ; YesNo with AlwaysOnTop flag
    )

    ; Restore always-on-top states
    if (settingsHwnd && settingsOnTop && WinExist("ahk_id " . settingsHwnd))
        WinSetAlwaysOnTop(1, "ahk_id " . settingsHwnd)
    if (shortcutsHwnd && shortcutsOnTop && WinExist("ahk_id " . shortcutsHwnd))
        WinSetAlwaysOnTop(1, "ahk_id " . shortcutsHwnd)

    Run(result = "Yes"
        ? "https://github.com/nvbangg/KeyClipboard"
            : "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    ; =)))))
}
