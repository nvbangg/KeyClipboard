; === CLIPBOARD MODULE ===

global clipHistory := []             ; Stores clipboard history items
global isFormatting := false         ; Flag for formatting in progress
global originalClip := ""            ; Stores original clipboard content
global clipHistoryGuiInstance := 0   ; Reference to clipboard history GUI
#Include "Clip_utils.ahk"
#Include "Clip_format.ahk"

addClipSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h200", "Format Options")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vremoveAccentsEnabled Checked" . removeAccentsEnabled,
        "Remove Accents")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vnormSpaceEnabled Checked" . normSpaceEnabled,
        "Normalize Spaces")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vremoveSpecialEnabled Checked" . removeSpecialEnabled,
        "Remove Special Characters (# *)")
    yPos += 35

    ; Text formatting options
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Line Break:")
    lineChoices := ["None", "Trim Lines", "Remove All Line Breaks"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vlineOption Choose" . (
        lineOption + 1),
    lineChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Text Case:")
    caseChoices := ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vcaseOption Choose" . (caseOption +
        1),
    caseChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Word Separator:")
    separatorChoices := ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vseparatorOption Choose" . (
        separatorOption + 1),
    separatorChoices)
    yPos += 30

    return yPos + 15
}

showClipboard() {
    global clipHistory, clipHistoryGuiInstance
    try {
        if (IsObject(clipHistoryGuiInstance) && clipHistoryGuiInstance.HasProp("Hwnd") && WinExist("ahk_id " .
            clipHistoryGuiInstance.Hwnd)) {
            clipHistoryGuiInstance.Destroy()
        }
    } catch {
        clipHistoryGuiInstance := 0
    }

    if (clipHistory.Length < 1) {
        showNotification("No items in clipboard history")
        return
    }

    clipHistoryGui := Gui(, "Clipboard History")
    clipHistoryGuiInstance := clipHistoryGui
    clipHistoryGui.SetFont("s10")

    ; Create ListView for clipboard items
    LV := clipHistoryGui.Add("ListView", "x10 y10 w700 h300 Grid Multi", ["#", "Content"])
    LV.ModifyCol(1, 50, "Integer")
    LV.ModifyCol(2, 640)

    LV.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipHistoryGui, Item, X, Y))

    contentViewer := clipHistoryGui.Add("Edit", "x10 y320 w700 h200 VScroll HScroll", "")
    LV.OnEvent("ItemSelect", (LV, *) => updateContent(LV, contentViewer))
    LV.OnEvent("ItemFocus", (LV, *) => updateContent(LV, contentViewer))

    clipHistoryGui.OnEvent("Close", (*) => clipHistoryGui.Destroy())
    clipHistoryGui.OnEvent("Escape", (*) => clipHistoryGui.Destroy())
    LV.OnEvent("DoubleClick", (*) => pasteSelected(LV, clipHistoryGui))

    ; Special hotkeys when clipboard history is active
    HotIfWinActive("ahk_id " . clipHistoryGui.Hwnd)
    Hotkey "Enter", (*) => isListViewFocused() ? pasteSelected(LV, clipHistoryGui) : Send("{Enter}")
    Hotkey "!Up", (*) => moveSelectedItem(LV, contentViewer, -1)
    Hotkey "!Down", (*) => moveSelectedItem(LV, contentViewer, 1)
    Hotkey "^a", (*) => isListViewFocused() ? LV.Modify(0, "Select") : Send("^a")
    Hotkey "Delete", (*) => deleteSelected(LV, clipHistoryGui)
    HotIf()

    updateLV(LV, clipHistoryGui)

    ; Select and focus the last item (most recent)
    lastRow := LV.GetCount()
    if (lastRow > 0) {
        LV.Modify(lastRow, "Select Focus Vis")
        updateContent(LV, contentViewer)
    }

    ; Add action buttons - now with help button
    buttonOptions := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(LV, contentViewer, clipHistoryGui)],
        ["x280 y530 w120", "Clear All", (*) => clearClipboard(clipHistoryGui)],
        ["x410 y530 w120", "Help", (*) => showClipboardHelp()]
    ]

    for option in buttonOptions
        clipHistoryGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])

    clipHistoryGui.Show("w720 h570")
}

; Show clipboard usage instructions
showClipboardHelp(*) {
    helpGui := Gui("+AlwaysOnTop +ToolWindow", "Clipboard Help")
    helpGui.SetFont("s10")

    helpText :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+A: Select all items in the list`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected item up/down in the list`n" .
        "• Right-click: Show context menu with more options`n`n"

    helpGui.Add("Text", "w350", helpText)
    helpGui.Add("Button", "w100 x120 y200 Default", "OK").OnEvent("Click", (*) => helpGui.Destroy())

    helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
    helpGui.OnEvent("Close", (*) => helpGui.Destroy())

    helpGui.Show()
}

; Context menu for clipboard items
showContextMenu(LV, clipHistoryGui, Item, X, Y) {
    if (Item = 0)
        return

    contentViewer := 0
    try contentViewer := clipHistoryGui.FindControl("Edit1")

    contextMenu := Menu()
    contextMenu.Add("Paste", (*) => pasteSelected(LV, clipHistoryGui))
    contextMenu.Add("Paste with Format", (*) => pasteSelected(LV, clipHistoryGui, true))
    contextMenu.Add("Paste as Original Format", (*) => pasteSelected(LV, clipHistoryGui, -1))
    contextMenu.Add("Save Format to Clipboard", (*) => saveToClipboard(LV, true))
    contextMenu.Add()
    contextMenu.Add("Delete Item", (*) => deleteSelected(LV, clipHistoryGui))
    contextMenu.Show(X, Y)
}
