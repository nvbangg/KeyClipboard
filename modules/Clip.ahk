; === CLIPBOARD MODULE ===
; Manages clipboard history, formatting, and paste operations

; Global state variables
global clipHistory := []             ; Stores clipboard history items
global isFormatting := false         ; Flag for formatting in progress
global originalClip := ""            ; Stores original clipboard content
global clipHistoryGuiInstance := 0   ; Reference to clipboard history GUI

#Include "Clip_utils.ahk"
#Include "Clip_format.ahk"

; Add clipboard settings UI to settings panel
addClipSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h175", "Format Options")
    yPos += 25

    settingsGui.Add("CheckBox", "x20 y" . yPos . " vnoAccentsEnabled Checked" . noAccentsEnabled,
        "Remove Accents")
    yPos += 25

    settingsGui.Add("CheckBox", "x20 y" . yPos . " vnormSpaceEnabled Checked" .
        normSpaceEnabled,
        "Normalize Spaces")
    yPos += 35

    ; Text formatting options
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Line Break:")
    lineBreakChoices := ["None", "Trim Lines", "Remove All Line Breaks"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vLineBreakOption Choose" . (
        lineBreakOption + 1),
    lineBreakChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Text Case:")
    caseChoices := ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vCaseOption Choose" . (formatCaseOption +
        1),
    caseChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Word Separator:")
    separatorChoices := ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vSeparatorOption Choose" . (
        formatSeparator + 1),
    separatorChoices)
    yPos += 30

    return yPos + 15
}

initClipboard()

; Display clipboard history in a GUI window
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
    Hotkey "Enter", (*) => saveContent(LV, contentViewer, clipHistoryGui, true)
    Hotkey "!Up", (*) => moveSelectedItem(LV, contentViewer, -1)
    Hotkey "!Down", (*) => moveSelectedItem(LV, contentViewer, 1)
    HotIf()

    updateLV(LV)
    updateContent(LV, contentViewer)

    ; Add action buttons
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

; Context menu for clipboard items
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

; Paste item from history with optional formatting
pastePrev(offset := 0, formatTextEnable := false) {
    global clipHistory

    if (clipHistory.Length < offset + 1) {
        showNotification("Not enough items in clipboard history")
        return
    }

    content := clipHistory[clipHistory.Length - offset]
    paste(content, formatTextEnable)
}

; Paste with specialized formatting options
pasteSpecific() {
    global clipHistory

    if (clipHistory.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }
    latest := clipHistory[clipHistory.Length]
    beforeLatest := clipHistory[clipHistory.Length - 1]
    content := beforeLatest . "_" . latest

    content := removeAccents(content)

    paste(content, false)
}

; Clear clipboard history
clearClipboard(clipHistoryGui := 0) {
    if (clipHistoryGui)
        clipHistoryGui.Destroy()
    global clipHistory
    clipHistory := []
    showNotification("All items have been cleared")
}
