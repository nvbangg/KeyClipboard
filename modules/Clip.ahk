; Clipboard functions

global clipboardHistory := []
global isFormatting := false
global originalClip := ""

#Include "Clip_utils.ahk"
#Include "Clip_format.ahk"
; Add clipboard settings to the settings interface
AddClipboardSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w380 h300", "Paste Format (Caps+F)")
    yPos += 25

    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h50", "1. Prefix_text (nội dung trước_nội dung sau)")
    yPos += 25
    settingsGui.Add("CheckBox", "x40 y" . yPos . " vprefix_textEnabled Checked" . prefix_textEnabled,
        "Bật chế độ Prefix_text")
    yPos += 35

    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h135", "2. Kiểu")
    yPos += 25

    radioOptions := [
        ["CaseNone", "None", 0],
        ["CaseUpper", "In hoa (UPPERCASE)", 1],
        ["CaseLower", "In thường (lowercase)", 2],
        ["CaseNoDiacritics", "In không dấu (Remove diacritics)", 3],
        ["CaseTitleCase", "In hoa chữ đầu (Title Case)", 4]
    ]

    for option in radioOptions {
        settingsGui.Add("Radio", "x40 y" . yPos . " v" . option[1] . " Checked" . (formatCaseOption = option[3]),
        option[2])
        yPos += 25
    }
    yPos += 10

    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h110", "3. Phân cách")
    yPos += 25

    separatorOptions := [
        ["SeparatorNone", "None", 0],
        ["SeparatorUnderscore", "Gạch dưới (_)", 1],
        ["SeparatorHyphen", "Gạch ngang (-)", 2],
        ["SeparatorNoSpace", "Xoá khoảng cách", 3]
    ]

    for option in separatorOptions {
        settingsGui.Add("Radio", "x40 y" . yPos . " v" . option[1] . " Checked" . (formatSeparator = option[3]),
        option[2])
        yPos += 25
    }

    return yPos + 15
}

InitClipboard()

; Display clipboard history and allow selection
ShowClipboardHistory() {
    global clipboardHistory
    if (clipboardHistory.Length = 0) {
        ShowNotification("No clipboard history available.")
        return
    }
    clipHistoryGui := Gui(, "Clipboard History")
    clipHistoryGui.SetFont("s10")
    LV := clipHistoryGui.Add("ListView", "x10 y10 w700 h300 Grid Multi", ["#", "Content"])
    LV.ModifyCol(1, 50, "Integer")
    LV.ModifyCol(2, 640)

    LV.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        ShowContextMenu(LV, clipHistoryGui, Item, X, Y))

    ; Add the content viewer
    contentViewer := clipHistoryGui.Add("Edit", "x10 y320 w700 h200 VScroll HScroll", "")
    LV.OnEvent("ItemSelect", (LV, *) => UpdateContentViewer(LV, contentViewer))
    LV.OnEvent("ItemFocus", (LV, *) => UpdateContentViewer(LV, contentViewer))

    ; Add window close handlers
    clipHistoryGui.OnEvent("Close", (*) => clipHistoryGui.Destroy())
    clipHistoryGui.OnEvent("Escape", (*) => clipHistoryGui.Destroy())

    LV.OnEvent("DoubleClick", (*) => PasteSelected(LV, clipHistoryGui))
    HotIfWinActive("ahk_id " clipHistoryGui.Hwnd)
    Hotkey "Enter", (*) => SaveAndPasteSelected(LV, contentViewer, clipHistoryGui)
    HotIf()

    UpdateLV(LV)
    UpdateContentViewer(LV, contentViewer)

    buttonOptions := [
        ["x10 y530 w100", "Paste All", (*) =>
            PasteSelected(GetAll(LV), clipHistoryGui)],
        ["x120 y530 w120", "Format Paste All", (*) => PasteSelected(GetAll(LV), clipHistoryGui, true)],
        ["x250 y530 w100", "Clear All", (*) => ClearAllHistory(clipHistoryGui)],
        ["x360 y530 w120", "Save Changes", (*) => SaveContentChanges(LV, contentViewer, clipHistoryGui)]
    ]

    for option in buttonOptions {
        clipHistoryGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])
    }

    clipHistoryGui.Show("w720 h570")
}

; Show context menu for right-click
ShowContextMenu(LV, clipHistoryGui, Item, X, Y) {
    if (Item = 0)
        return
    contextMenu := Menu()
    contextMenu.Add("Paste", (*) => PasteSelected(LV, clipHistoryGui))
    contextMenu.Add("Format Paste", (*) => PasteSelected(LV, clipHistoryGui, true))
    contextMenu.Add()
    contextMenu.Add("Delete Item",
        (*) => DeleteSelected(LV, clipHistoryGui))
    contextMenu.Show(X, Y)
}

; Paste the previous clipboard content
PastePreviousClipboard() {
    global clipboardHistory

    if (clipboardHistory.Length < 2) {
        ShowNotification("Not enough clipboard history to paste previous item.")
        return
    }

    Paste(clipboardHistory[clipboardHistory.Length - 1])
}

PasteWithCurrentFormat() {
    global clipboardHistory, prefix_textEnabled

    if (clipboardHistory.Length < 1) {
        ShowNotification("No items in clipboard history")
        return
    }
    Content := clipboardHistory[clipboardHistory.Length]

    if (prefix_textEnabled) {
        if (clipboardHistory.Length > 1) {
            prevContent := clipboardHistory[clipboardHistory.Length - 1]
            Content := prevContent . "_" . Content
        }
    }
    Paste(Content, true)
}

; Clear clipboard history
ClearAllHistory(clipHistoryGui := 0) {
    if (clipHistoryGui)
        clipHistoryGui.Destroy()
    global clipboardHistory
    clipboardHistory := []
    ShowNotification("All items have been cleared.")
}
