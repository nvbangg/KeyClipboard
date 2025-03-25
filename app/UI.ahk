;=== UI MODULE ===

A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showSettings(*) {
    static settingsGui := 0
    static isCreating := false
    if (isCreating)
        return
    isCreating := true

    ; Clean up existing GUI - safer checking
    if IsObject(settingsGui) {
        SetTimer(() => CheckGuiOutsideClick(settingsGui, true), 0)
        settingsGui.Destroy()
        settingsGui := 0
    }

    ; Create new settings GUI
    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10
    yPos := addKeySettings(settingsGui, yPos)
    yPos := addClipSettings(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save")
    .OnEvent("Click", (*) => CloseAndSave())
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts")
    .OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About")
    .OnEvent("Click", (*) => showAbout())

    settingsGui.Show("w375 h" . (yPos + 50))
    settingsGui.OnEvent("Escape", (*) => CloseAndSave())
    settingsGui.OnEvent("Close", (*) => CloseAndSave())
    SetTimer(() => CheckGuiOutsideClick(settingsGui, true), 100)

    isCreating := false

    ; Helper function for saving and closing
    CloseAndSave() {
        SetTimer(() => CheckGuiOutsideClick(settingsGui, true), 0)
        saveSettings(settingsGui.Submit())
        settingsGui.Destroy()
        settingsGui := 0  ; Reset after destroying

    }
}

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
        "• CapsLock+Shift+V/B/A: Paste item(s) as Original`n" .
        "• CapsLock+Ctrl+V/B/A: Paste item(s) from Saved tab`n" .
        "• CapsLock+1-9: Paste item by position from saved tab`n"
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
        "Version: 1.6.1.1`n" .
        "Date: 24/03/2025`n`n" .
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
