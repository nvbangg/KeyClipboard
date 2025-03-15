; Clipboard functions

global clipHistory := []
global isFormatting := false
global originalClip := ""
global clipHistoryGuiInstance := 0
global removeDiacriticsEnabled := false
global removeExcessiveSpacesEnabled := false  ; Add new option for space handling
global lineBreakOption := 0  ; Replace removeLineBreaksEnabled with more flexible option
#Include "Clip_utils.ahk"
#Include "Clip_format.ahk"

addClipSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w440 h350", "Paste Format (Caps+F)")
    yPos += 25

    ; Independent checkbox options
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w420 h110", "Format Options")
    yPos += 25

    settingsGui.Add("CheckBox", "x40 y" . yPos . " vbeforeLatest_LatestEnabled Checked" . beforeLatest_LatestEnabled,
        "Enable beforeLatest_Latest")
    yPos += 25

    settingsGui.Add("CheckBox", "x40 y" . yPos . " vremoveDiacriticsEnabled Checked" . removeDiacriticsEnabled,
        "Remove Diacritics")
    yPos += 25

    settingsGui.Add("CheckBox", "x40 y" . yPos . " vremoveExcessiveSpacesEnabled Checked" .
        removeExcessiveSpacesEnabled,
        "Fix Spacing Around Punctuation")
    yPos += 35

    ; Line break options - Converted to dropdown with AltSubmit
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Line Break Handling:")  ; Increased label width from 120 to 150
    lineBreakChoices := ["None", "Remove Excessive Line Breaks", "Remove All Line Breaks"]
    settingsGui.Add("DropDownList", "x180 y" . (yPos - 3) . " w250 AltSubmit vLineBreakOption Choose" . (
        lineBreakOption + 1),  ; Adjusted X position from 150 to 180
    lineBreakChoices)
    yPos += 30

    ; Text case options - Converted to dropdown with AltSubmit
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Text Case:")  ; Increased label width from 120 to 150
    caseChoices := ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"]
    settingsGui.Add("DropDownList", "x180 y" . (yPos - 3) . " w250 AltSubmit vCaseOption Choose" . (formatCaseOption +
        1),  ; Adjusted X position from 150 to 180
    caseChoices)
    yPos += 30

    ; Separator options - Converted to dropdown with AltSubmit
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Word Separator:")  ; Increased label width from 120 to 150
    separatorChoices := ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"]
    settingsGui.Add("DropDownList", "x180 y" . (yPos - 3) . " w250 AltSubmit vSeparatorOption Choose" . (
        formatSeparator + 1),  ; Adjusted X position from 150 to 180
    separatorChoices)
    yPos += 30

    return yPos + 15
}

initClipboard()

; Display clipboard history and allow selection
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
    LV := clipHistoryGui.Add("ListView", "x10 y10 w700 h300 Grid Multi", ["#", "Content"])
    LV.ModifyCol(1, 50, "Integer")
    LV.ModifyCol(2, 640)

    LV.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipHistoryGui, Item, X, Y))

    ; Add the content viewer
    contentViewer := clipHistoryGui.Add("Edit", "x10 y320 w700 h200 VScroll HScroll", "")
    LV.OnEvent("ItemSelect", (LV, *) => updateContent(LV, contentViewer))
    LV.OnEvent("ItemFocus", (LV, *) => updateContent(LV, contentViewer))

    ; Add window close handlers
    clipHistoryGui.OnEvent("Close", (*) => clipHistoryGui.Destroy())
    clipHistoryGui.OnEvent("Escape", (*) => clipHistoryGui.Destroy())
    LV.OnEvent("DoubleClick", (*) => pasteSelected(LV, clipHistoryGui))

    HotIfWinActive("ahk_id " . clipHistoryGui.Hwnd)
    Hotkey "Enter", (*) => saveContent(LV, contentViewer, clipHistoryGui, true)

    ; Improved hotkey definitions for moving items
    Hotkey "!Up", (*) => moveSelectedItem(LV, contentViewer, -1)    ; Alt+Up arrow
    Hotkey "!Down", (*) => moveSelectedItem(LV, contentViewer, 1)   ; Alt+Down arrow
    HotIf()

    updateLV(LV)
    updateContent(LV, contentViewer)

    buttonOptions := [
        ["x10 y530 w100", "Paste All", (*) =>
            pasteSelected(getAll(LV), clipHistoryGui)],
        ["x120 y530 w120", "Format Paste All", (*) => pasteSelected(getAll(LV), clipHistoryGui, true)],
        ["x250 y530 w100", "Clear All", (*) => clearClipboard(clipHistoryGui)],
        ["x360 y530 w120", "Save Changes", (*) => saveContent(LV, contentViewer, clipHistoryGui)]
    ]

    for option in buttonOptions
        clipHistoryGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])

    clipHistoryGui.Show("w720 h570")
}

; Show context menu for right-click
showContextMenu(LV, clipHistoryGui, Item, X, Y) {
    if (Item = 0)
        return
    contextMenu := Menu()
    contextMenu.Add("Paste", (*) => pasteSelected(LV, clipHistoryGui))
    contextMenu.Add("Paste with Format", (*) => pasteSelected(LV, clipHistoryGui, true))
    contextMenu.Add("Save Format to Clipboard", (*) => saveToClipboard(LV, true))
    contextMenu.Add()
    contextMenu.Add("Delete Item", (*) => deleteSelected(LV, clipHistoryGui))
    contextMenu.Show(X, Y)
}

; Paste the previous clipboard content
pasteBeforeLatest() {
    global clipHistory
    if (clipHistory.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }
    paste(clipHistory[clipHistory.Length - 1])
}

pasteLatest() {
    global clipHistory
    if (clipHistory.Length < 1) {
        showNotification("No items in clipboard history")
        return
    }
    paste(clipHistory[clipHistory.Length])
}

formatWhenPaste() {
    global clipHistory, beforeLatest_LatestEnabled

    if (clipHistory.Length < 1) {
        showNotification("No items in clipboard history")
        return
    }
    content := clipHistory[clipHistory.Length]

    if (beforeLatest_LatestEnabled) {
        if (clipHistory.Length > 1) {
            prevContent := clipHistory[clipHistory.Length - 1]
            content := prevContent . "_" . content
        }
    }
    paste(content, true)
}

; Clear clipboard history
clearClipboard(clipHistoryGui := 0) {
    if (clipHistoryGui)
        clipHistoryGui.Destroy()
    global clipHistory
    clipHistory := []
    showNotification("All items have been cleared")
}
