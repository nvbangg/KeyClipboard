; Clipboard functions

global clipboardHistory := []
global isFormatting := false
global originalClip := ""

#Include "Clip_utils.ahk"

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

    LV := clipHistoryGui.Add("ListView", "x10 y10 w700 h400 Grid", ["#", "Content"])
    LV.OnEvent("DoubleClick", PasteSelected)
    LV.OnEvent("ContextMenu", ShowContextMenu)
    LV.ModifyCol(1, 50)
    LV.ModifyCol(2, 640)

    for index, content in clipboardHistory {
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        LV.Add(, index, displayContent)
    }
    LV.Modify(1, "Select Focus")

    buttonOptions := [
        ["x10 y420 w100 Default", "Paste", PasteSelected],
        ["x120 y420 w100", "Paste All", PasteAllItems],
        ["x230 y420 w120", "Format Paste All", FormatPasteAllItems],
        ["x360 y420 w100", "Clear All", ClearAllHistory]
    ]

    for option in buttonOptions {
        clipHistoryGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])
    }

    clipHistoryGui.Show("w720 h460")

    ; Paste selected item
    PasteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            selected_index := LV.GetText(focused_row, 1)
            clipHistoryGui.Destroy()
            PasteWithFormat(clipboardHistory[selected_index])
        }
    }

    ; Paste all items with line breaks
    PasteAllItems(*) {
        clipHistoryGui.Destroy()

        combinedContent := ""
        for index, content in clipboardHistory {
            combinedContent .= content . (index < clipboardHistory.Length ? "`r`n" : "")
        }

        PasteWithFormat(combinedContent)
    }

    ; Format and paste all items
    FormatPasteAllItems(*) {
        clipHistoryGui.Destroy()
        formattedContent := ""

        for index, content in clipboardHistory {
            prefix := (index > 1 && prefix_textEnabled) ? clipboardHistory[index - 1] : ""
            formattedText := FormatClipboardText(content, prefix)
            formattedContent .= formattedText . (index < clipboardHistory.Length ? "`r`n" : "")
        }

        PasteWithFormat(formattedContent)
    }

    ; Format and paste selected item
    FormatPasteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            selected_index := LV.GetText(focused_row, 1)
            text := clipboardHistory[selected_index]

            prefix := (selected_index > 1) ? clipboardHistory[selected_index - 1] : ""
            formattedText := FormatClipboardText(text, prefix)

            clipHistoryGui.Destroy()
            PasteWithFormat(formattedText)
        }
    }

    ; Clear all clipboard history
    ClearAllHistory(*) {
        global clipboardHistory
        clipboardHistory := []
        clipHistoryGui.Destroy()
        ShowNotification("All items in clipboard history have been cleared.")
    }

    ; Show context menu for right-click
    ShowContextMenu(LV, Item, IsRightClick, X, Y) {
        if (Item = 0)
            return

        contextMenu := Menu()
        contextMenu.Add("Paste", PasteSelected)
        contextMenu.Add("Format Paste", FormatPasteSelected)
        contextMenu.Add()
        contextMenu.Add("Delete item", DeleteSelected)
        contextMenu.Show(X, Y)
    }

    ; Delete selected item
    DeleteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            selected_index := LV.GetText(focused_row, 1)
            clipboardHistory.RemoveAt(selected_index)

            LV.Delete()
            LV.Delete()  ; Clear all rows

            for index, content in clipboardHistory {
                displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
                LV.Add(, index, displayContent)
            }

            if (clipboardHistory.Length = 0) {
                clipHistoryGui.Destroy()
                ShowNotification("All items in clipboard history have been deleted.")
            }
        }
    }
}

; Paste the previous clipboard content
PastePreviousClipboard() {
    global clipboardHistory

    if (clipboardHistory.Length < 2) {
        ShowNotification("Not enough clipboard history to paste previous item.")
        return
    }

    PasteWithFormat(clipboardHistory[clipboardHistory.Length - 1])
}

; Format and paste clipboard content based on settings
PasteWithCurrentFormat() {
    global clipboardHistory

    if (clipboardHistory.Length < 1) {
        ShowNotification("No clipboard content to format.")
        return
    }

    text := clipboardHistory[clipboardHistory.Length]
    prefix := (clipboardHistory.Length >= 2) ? clipboardHistory[clipboardHistory.Length - 1] : ""

    PasteWithFormat(FormatClipboardText(text, prefix))
}
