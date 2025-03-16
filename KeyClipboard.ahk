; KeyClipboard - Advanced clipboard manager and keyboard automation tool
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "modules\Common.ahk"
#Include "modules\Clip.ahk"
#Include "modules\Key.ahk"

; === INITIALIZATION ===
initSettings()

; === KeyBoard HOTKEYS ===

#HotIf mouseEnabled
RAlt:: Click()
RCtrl:: Click("Right")
#HotIf

#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: translateInChrome()
#HotIf

CapsLock & w:: toggleAlwaysOnTop()
CapsLock & s:: showSettings()

; === CLIPBOARD MANAGEMENT ===
CapsLock & Space:: showClipboard()
CapsLock & c:: clearClipboard()
CapsLock & f:: pasteSpecific()

#HotIf GetKeyState("CapsLock", "P")
v:: pastePrev(0, false)
+v:: pastePrev(0, true)
b:: pastePrev(1, false)
+b:: pastePrev(1, true)
a:: pasteSelected()
+a:: pasteSelected(, , true)
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

showAbout(*) {
    ; Find settings window if it exists
    settingsHwnd := WinExist("KeyClipboard - Settings")

    ; If settings window exists, temporarily remove its always-on-top status
    wasAlwaysOnTop := false
    if (settingsHwnd) {
        wasAlwaysOnTop := WinGetExStyle(settingsHwnd) & 0x8
        WinSetAlwaysOnTop(0, "ahk_id " . settingsHwnd)
    }

    result := MsgBox("KeyClipboard`n" .
        "Version: 1.5.3.2`n" .
        "Date: 16/03/2025`n" .
        "`nSource: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open",
        "About KeyClipboard", "YesNo")

    ; Restore settings window's always-on-top status
    if (settingsHwnd && wasAlwaysOnTop && WinExist("ahk_id " . settingsHwnd)) {
        try {
            WinSetAlwaysOnTop(1, "ahk_id " . settingsHwnd)
        } catch {
            ; Silently ignore if window can't be modified
        }
    }

    if (result = "Yes")
        Run("https://github.com/nvbangg/KeyClipboard")
    else
        Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    ;   =)))))
}

showShortcuts(*) {
    static shortcutsGui := 0

    try {
        if IsObject(shortcutsGui) && shortcutsGui.HasProp("Hwnd")
            if WinExist("ahk_id " . shortcutsGui.Hwnd)
                shortcutsGui.Destroy()
    } catch {
        ; If any error occurs, just create a new GUI
    }

    ; Create new GUI with appropriate options
    shortcutsGui := Gui("+AlwaysOnTop +ToolWindow")
    shortcutsGui.Title := "Shortcuts - KeyClipboard"
    shortcutsGui.SetFont("s10")
    shortcutsGui.OnEvent("Escape", CloseShortcutsGui)

    ; Add shortcuts text
    shortcutsGui.Add("Text", "w375",
        "CapsLock+S: Show Settings Popup`n" .
        "CapsLock+W: Toggle Always-on-Top for active Window`n" .
        "CapsLock+T: Translate page in Chrome`n`n" .
        ;
        "CapsLock+V: Paste latest item from clipboard history`n" .
        "CapsLock+B: Paste the item before the latest`n" .
        "CapsLock+A: Paste all clipboard items`n" .
        "CapsLock+Shift+V/ B/ A: Paste item with format`n`n" .
        ;
        "CapsLock+Space: Show Clipboard History`n" .
        "CapsLock+C: Clear clipboard history`n" .
        "Alt+Up/Down: Move selected item up/down in the list`n" .
        "CapsLock+F: Paste combining previous and current items`n"
    )

    shortcutsGui.Add("Button", "Default w80", "OK").OnEvent("Click", CloseShortcutsGui)
    shortcutsGui.Show()
    myGui := shortcutsGui
    SetTimer () => CheckOutsideClick(myGui), 100

    CloseShortcutsGui(*) {
        SetTimer () => CheckOutsideClick(myGui), 0
        if IsObject(shortcutsGui) {
            try shortcutsGui.Destroy()
            shortcutsGui := 0
        }
    }
}
