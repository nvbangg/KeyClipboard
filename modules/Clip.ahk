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
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w380 h450", "Paste Format (Caps+F)")
    yPos += 25

    ; Independent checkbox options
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h110", "Format Options")
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

    ; Line break options
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h110", "Line Break Handling")
    yPos += 25

    lineBreakOptions := [
        ["LineBreakNone", "None", 0],
        ["LineBreakRemoveExcessive", "Remove Excessive Line Breaks", 1],
        ["LineBreakRemoveAll", "Remove All Line Breaks", 2]
    ]
    for option in lineBreakOptions {
        settingsGui.Add("Radio", "x40 y" . yPos . " v" . option[1] . " Checked" . (lineBreakOption = option[3]),
        option[2])
        yPos += 25
    }

    ; Text case options (radio buttons)
    yPos += 10
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h140", "Text Case")
    yPos += 25

    caseOptions := [
        ["CaseNone", "None", 0],
        ["CaseUpper", "UPPERCASE", 1],
        ["CaseLower", "lowercase", 2],
        ["CaseTitleCase", "Title Case", 3],
        ["CaseSentence", "Sentence case", 4]
    ]
    for option in caseOptions {
        settingsGui.Add("Radio", "x40 y" . yPos . " v" . option[1] . " Checked" . (formatCaseOption = option[3]),
        option[2])
        yPos += 25
    }

    ; Separator options
    yPos += 10
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h110", "Word Separator")
    yPos += 25

    separatorOptions := [
        ["SeparatorNone", "None", 0],
        ["SeparatorUnderscore", "Underscore (_)", 1],
        ["SeparatorHyphen", "Hyphen (-)", 2],
        ["SeparatorNoSpace", "Remove Spaces", 3]
    ]
    for option in separatorOptions {
        settingsGui.Add("Radio", "x40 y" . yPos . " v" . option[1] . " Checked" . (formatSeparator = option[3]),
        option[2])
        yPos += 25
    }

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
