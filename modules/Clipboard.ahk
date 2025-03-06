; Clipboard manager

clipboardHistory := []
isFormatting := false
originalClip := ""

; Map of all Vietnamese diacritics to non-diacritic characters
global accentMap := Map(
    "à", "a", "á", "a", "ả", "a", "ã", "a", "ạ", "a",
    "ă", "a", "ằ", "a", "ắ", "a", "ẳ", "a", "ẵ", "a", "ặ", "a",
    "â", "a", "ầ", "a", "ấ", "a", "ẩ", "a", "ẫ", "a", "ậ", "a",
    "è", "e", "é", "e", "ẻ", "e", "ẽ", "e", "ẹ", "e",
    "ê", "e", "ề", "e", "ế", "e", "ể", "e", "ễ", "e", "ệ", "e",
    "ì", "i", "í", "i", "ỉ", "i", "ĩ", "i", "ị", "i",
    "ò", "o", "ó", "o", "ỏ", "o", "õ", "o", "ọ", "o",
    "ô", "o", "ồ", "o", "ố", "o", "ổ", "o", "ỗ", "o", "ộ", "o",
    "ơ", "o", "ờ", "o", "ớ", "o", "ở", "o", "ỡ", "o", "ợ", "o",
    "ù", "u", "ú", "u", "ủ", "u", "ũ", "u", "ụ", "u",
    "ư", "u", "ừ", "u", "ứ", "u", "ử", "u", "ữ", "u", "ự", "u",
    "ỳ", "y", "ý", "y", "ỷ", "y", "ỹ", "y", "ỵ", "y", "đ", "d",
    "À", "A", "Á", "A", "Ả", "A", "Ã", "A", "Ạ", "A",
    "Ă", "A", "Ằ", "A", "Ắ", "A", "Ẳ", "A", "Ẵ", "A", "Ặ", "A",
    "Â", "A", "Ầ", "A", "Ấ", "A", "Ẩ", "A", "Ẫ", "A", "Ậ", "A",
    "È", "E", "É", "E", "Ẻ", "E", "Ẽ", "E", "Ẹ", "E",
    "Ê", "E", "Ề", "E", "Ế", "E", "Ể", "E", "Ễ", "E", "Ệ", "E",
    "Ì", "I", "Í", "I", "Ỉ", "I", "Ĩ", "I", "Ị", "I",
    "Ò", "O", "Ó", "O", "Ỏ", "O", "Õ", "O", "Ọ", "O",
    "Ô", "O", "Ồ", "O", "Ố", "O", "Ổ", "O", "Ỗ", "O", "Ộ", "O",
    "Ơ", "O", "Ờ", "O", "Ớ", "O", "Ở", "O", "Ỡ", "O", "Ợ", "O",
    "Ù", "U", "Ú", "U", "Ủ", "U", "Ũ", "U", "Ụ", "U",
    "Ư", "U", "Ừ", "U", "Ứ", "U", "Ử", "U", "Ữ", "U", "Ự", "U",
    "Ỳ", "Y", "Ý", "Y", "Ỷ", "Y", "Ỹ", "Y", "Ỵ", "Y", "Đ", "D"
)

; Add clipboard settings to the settings GUI
AddClipboardSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w380 h300", "Paste Format (Caps+F)")

    yPos += 25

    ; Section 1: Code Filename Format (moved to first position)
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h50", "1. Prefix_text")

    yPos += 25
    settingsGui.Add("CheckBox", "x40 y" . yPos . " vprefix_textEnabled Checked" . prefix_textEnabled,
        "Bật chế độ Prefix_text")

    yPos += 35

    ; Section 2: Text Case Format (now second position)
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h135", "2. Kiểu")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vCaseNone Checked" . (formatCaseOption = 0),
    "None")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vCaseUpper Checked" . (formatCaseOption = 1),
    "In hoa (UPPERCASE)")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vCaseLower Checked" . (formatCaseOption = 2),
    "In thường (lowercase)")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vCaseNoDiacritics Checked" . (formatCaseOption = 3),
    "In không dấu (Remove diacritics)")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vCaseTitleCase Checked" . (formatCaseOption = 4),
    "In hoa chữ đầu (Title Case)")

    yPos += 35

    ; Section 3: Word Separator (now third position)
    settingsGui.Add("GroupBox", "x20 y" . yPos . " w360 h110", "3. Phân cách")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vSeparatorNone Checked" . (formatSeparator = 0),
    "None")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vSeparatorUnderscore Checked" . (formatSeparator = 1),
    "Gạch dưới (_)")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vSeparatorHyphen Checked" . (formatSeparator = 2),
    "Gạch ngang (-)")

    yPos += 25
    settingsGui.Add("Radio", "x40 y" . yPos . " vSeparatorNoSpace Checked" . (formatSeparator = 3),
    "Xoá khoảng cách")

    return yPos + 40
}

; Initialize clipboard tracking
InitClipboard()
InitClipboard() {
    global clipboardHistory
    clipboardHistory := []
    OnClipboardChange(ClipChanged, 1)
}

; Handle clipboard content changes
ClipChanged(Type) {
    global clipboardHistory, isFormatting, originalClip

    if (isFormatting) {
        return
    }

    if Type = 1 {
        try {
            if (A_Clipboard != "") {
                clipboardHistory.Push(A_Clipboard)

                while clipboardHistory.Length > 50
                    clipboardHistory.RemoveAt(1)
            }
        }
    }
}

; Show clipboard history and allow selection
CapsLock & v:: {
    global clipboardHistory

    if (clipboardHistory.Length = 0) {
        MsgBox("No clipboard history available.", "Notice", "Icon!")
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
        stt := index
        LV.Add(, stt, displayContent)
    }

    LV.Modify(1, "Select Focus")

    clipHistoryGui.Add("Button", "x10 y420 w100 Default", "Paste").OnEvent("Click", PasteSelected)
    clipHistoryGui.Add("Button", "x120 y420 w100", "Paste All").OnEvent("Click", PasteAllItems)
    clipHistoryGui.Add("Button", "x230 y420 w120", "Format Paste All").OnEvent("Click", FormatPasteAllItems)
    clipHistoryGui.Add("Button", "x360 y420 w100", "Clear All").OnEvent("Click", ClearAllHistory)

    clipHistoryGui.Show("w720 h460")

    PasteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting

            isFormatting := true
            originalClip := ClipboardAll()

            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := clipboardHistory[selected_index]

            ClipWait(0.3)
            clipHistoryGui.Destroy()
            Send("^v")
            Sleep(100)

            A_Clipboard := originalClip
            ClipWait(0.3)
            Sleep(100)

            isFormatting := false
        }
    }

    PasteAllItems(*) {
        global isFormatting, clipboardHistory

        ; Set formatting flag before destroying GUI to prevent race conditions
        isFormatting := true

        ; Store original clipboard
        originalClip := ClipboardAll()

        ; Close the GUI first
        clipHistoryGui.Destroy()

        ; Prepare the combined content
        combinedContent := ""
        for index, content in clipboardHistory {
            combinedContent .= content

            if (index < clipboardHistory.Length)
                combinedContent .= "`r`n"
        }

        ; Paste the combined content
        A_Clipboard := combinedContent
        ClipWait(0.5)
        Send("^v")
        Sleep(100)

        ; Restore original clipboard
        A_Clipboard := originalClip
        ClipWait(0.5)
        Sleep(100)

        ; Clear formatting flag after everything is done
        isFormatting := false
    }

    FormatPasteAllItems(*) {
        global isFormatting, clipboardHistory

        ; Set formatting flag before destroying GUI to prevent race conditions
        isFormatting := true

        ; Store original clipboard
        originalClip := ClipboardAll()

        ; Close the GUI first
        clipHistoryGui.Destroy()

        ; Prepare the combined content with formatting applied
        formattedContent := ""
        for index, content in clipboardHistory {
            ; Determine if we should use the previous item as prefix
            prefix := ""
            if (index > 1 && prefix_textEnabled) {
                prefix := clipboardHistory[index - 1]
            }

            ; Format each item
            formattedText := FormatClipboardText(content, prefix)
            formattedContent .= formattedText

            if (index < clipboardHistory.Length)
                formattedContent .= "`r`n"
        }

        ; Paste the formatted content
        A_Clipboard := formattedContent
        ClipWait(0.5)
        Send("^v")
        Sleep(100)

        ; Restore original clipboard
        A_Clipboard := originalClip
        ClipWait(0.5)
        Sleep(100)

        ; Clear formatting flag after everything is done
        isFormatting := false
    }

    FormatPasteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting, clipboardHistory, formatCaseOption, formatSeparator, prefix_textEnabled

            isFormatting := true
            originalClip := ClipboardAll()

            selected_index := LV.GetText(focused_row, 1)
            text := clipboardHistory[selected_index]

            ; Apply the formatting according to current settings
            formattedText := FormatClipboardText(text, (selected_index > 1) ? clipboardHistory[selected_index - 1] : ""
            )

            A_Clipboard := formattedText

            ClipWait(0.3)
            clipHistoryGui.Destroy()
            Send("^v")
            Sleep(100)

            A_Clipboard := originalClip
            ClipWait(0.3)
            Sleep(100)

            isFormatting := false
        }
    }

    ClearAllHistory(*) {
        global clipboardHistory

        clipboardHistory := []
        clipHistoryGui.Destroy()
        MsgBox("All items in clipboard history have been successfully cleared.", "Clipboard Cleared", "IconI")
    }

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

    DeleteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            global clipboardHistory

            selected_index := LV.GetText(focused_row, 1)
            clipboardHistory.RemoveAt(selected_index)

            LV.Delete()

            for index, content in clipboardHistory {
                displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content

                LV.Add(, index, displayContent)
            }

            if (clipboardHistory.Length = 0) {
                clipHistoryGui.Destroy()
                MsgBox("All items in clipboard history have been deleted.", "Notice", "Icon!")
            }
        }
    }
}

; Paste previous clipboard content
CapsLock & z:: {
    global isFormatting, clipboardHistory

    if (clipboardHistory.Length < 2) {
        MsgBox("Not enough clipboard history to paste previous item.", "Notice", "Icon!")
        return
    }

    isFormatting := true
    originalClip := ClipboardAll()

    A_Clipboard := clipboardHistory[clipboardHistory.Length - 1]
    ClipWait(0.3)
    Send("^v")
    Sleep(100)

    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(100)

    isFormatting := false
}

; Format and paste clipboard content based on settings
CapsLock & f:: {
    global isFormatting, clipboardHistory

    if (clipboardHistory.Length < 1) {
        MsgBox("No clipboard content to format.", "Notice", "Icon!")
        return
    }

    isFormatting := true
    originalClip := ClipboardAll()

    ; Get the last clipboard item as our text
    text := clipboardHistory[clipboardHistory.Length]

    ; Get potential prefix from the previous item
    prefix := ""
    if (clipboardHistory.Length >= 2) {
        prefix := clipboardHistory[clipboardHistory.Length - 1]
    }

    ; Apply formatting using the shared function
    A_Clipboard := FormatClipboardText(text, prefix)

    ; Paste the formatted text
    ClipWait(0.3)
    Send("^v")
    Sleep(100)

    ; Restore the original clipboard
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(100)

    isFormatting := false
}

; Format text according to current settings
FormatClipboardText(text, prefixText := "") {
    global formatCaseOption, formatSeparator, prefix_textEnabled

    ; Make a copy to avoid modifying the original
    formattedText := text
    prefix := prefixText

    ; Use prefix_text mode if enabled and a prefix is available
    usePrefixMode := prefix_textEnabled && (prefix != "")

    ; Step 1: Apply text case formatting
    if (formatCaseOption = 1) {
        ; UPPERCASE
        formattedText := StrUpper(formattedText)
        if (usePrefixMode)
            prefix := StrUpper(prefix)
    } else if (formatCaseOption = 2) {
        ; lowercase
        formattedText := StrLower(formattedText)
        if (usePrefixMode)
            prefix := StrLower(prefix)
    } else if (formatCaseOption = 3) {
        ; Remove diacritics
        formattedText := RemoveAccents(formattedText)
        if (usePrefixMode)
            prefix := RemoveAccents(prefix)
    } else if (formatCaseOption = 4) {
        ; Title Case
        formattedText := ToTitleCase(formattedText)
        if (usePrefixMode)
            prefix := ToTitleCase(prefix)
    }

    ; Step 2: Apply separator transformation
    if (formatSeparator = 1) {
        ; Underscore
        formattedText := StrReplace(formattedText, " ", "_")
    } else if (formatSeparator = 2) {
        ; Hyphen
        formattedText := StrReplace(formattedText, " ", "-")
    } else if (formatSeparator = 3) {
        ; No separator (remove spaces)
        formattedText := StrReplace(formattedText, " ", "")
    }

    ; Step 3: Apply prefix_text format if needed
    if (usePrefixMode) {
        return prefix . "_" . formattedText . "."
    } else {
        return formattedText
    }
}

; Remove Vietnamese diacritics from text
RemoveAccents(str) {
    result := ""
    loop parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

; Helper function to convert text to Title Case
ToTitleCase(str) {
    result := ""
    nextIsTitle := true

    loop parse, str {
        if (A_LoopField = " " || A_LoopField = "_" || A_LoopField = "-") {
            result .= A_LoopField
            nextIsTitle := true
        } else if (nextIsTitle) {
            result .= StrUpper(A_LoopField)
            nextIsTitle := false
        } else {
            result .= StrLower(A_LoopField)
        }
    }

    return result
}
