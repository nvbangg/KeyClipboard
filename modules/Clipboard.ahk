; Clipboard manager

clipboardHistory := []
isFormatting := false
originalClip := ""

; Map of all Vietnamese diacritics to non-diacritic characters
global accentMap := Map(
    ; lowercase vowels
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
    
    ; uppercase vowels
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

; Remove Vietnamese diacritics from text
RemoveAccents(str) {
    result := ""
    Loop Parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

; Add clipboard settings to the settings GUI
AddClipboardSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w380 h150", "Paste Format (Caps+F)")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption1 Checked" . (pasteFormatMode = 1), 
                   "Paste with code filename format (default)")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption2 Checked" . (pasteFormatMode = 2), 
                   "Paste without diacritics")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption3 Checked" . (pasteFormatMode = 3), 
                   "Paste as UPPERCASE")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption4 Checked" . (pasteFormatMode = 4), 
                   "Paste as lowercase")
    
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
                
                while clipboardHistory.Length > 30
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
    clipHistoryGui.Add("Button", "x230 y420 w100", "Clear All").OnEvent("Click", ClearAllHistory)
    
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
        contextMenu.Add("Paste as filename", PasteAsFilename)
        contextMenu.Add("Paste without diacritics", PasteWithoutAccents)
        contextMenu.Add("Paste as UPPERCASE", PasteAsUppercase)
        contextMenu.Add("Paste as lowercase", PasteAsLowercase)
        contextMenu.Add()
        contextMenu.Add("Delete item", DeleteSelected)
        
        contextMenu.Show(X, Y)
    }
    
    PasteWithoutAccents(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting
            
            isFormatting := true
            originalClip := ClipboardAll()
            
            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := RemoveAccents(clipboardHistory[selected_index])
            
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
    
    PasteAsFilename(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting, clipboardHistory
            
            isFormatting := true
            originalClip := ClipboardAll()
            
            selected_index := LV.GetText(focused_row, 1)
            
            if (selected_index > 1) {
                prefix := clipboardHistory[selected_index - 1]
            } else if (clipboardHistory.Length > 1) {
                prefix := clipboardHistory[clipboardHistory.Length]
            } else {
                prefix := ""
            }
            
            if (prefix)
                A_Clipboard := prefix . "_" . RemoveAccents(clipboardHistory[selected_index]) . "."
            else
                A_Clipboard := RemoveAccents(clipboardHistory[selected_index]) . "."
            
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
    
    PasteAsUppercase(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting
            
            isFormatting := true
            originalClip := ClipboardAll()
            
            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := StrUpper(clipboardHistory[selected_index])
            
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
    
    PasteAsLowercase(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting
            
            isFormatting := true
            originalClip := ClipboardAll()
            
            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := StrLower(clipboardHistory[selected_index])
            
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
    
    if (pasteFormatMode = 1 && clipboardHistory.Length < 2) {
        MsgBox("Code filename format requires at least 2 items in clipboard history.", "Notice", "Icon!")
        return
    }
    
    isFormatting := true
    originalClip := ClipboardAll()
    
    if (pasteFormatMode = 1 && clipboardHistory.Length >= 2) {
        A_Clipboard := clipboardHistory[clipboardHistory.Length - 1] . "_" . 
                       RemoveAccents(clipboardHistory[clipboardHistory.Length]) . "."
    } else if (pasteFormatMode = 2) {
        A_Clipboard := RemoveAccents(clipboardHistory[clipboardHistory.Length])
    } else if (pasteFormatMode = 3) {
        A_Clipboard := StrUpper(clipboardHistory[clipboardHistory.Length])
    } else if (pasteFormatMode = 4) {
        A_Clipboard := StrLower(clipboardHistory[clipboardHistory.Length])
    } else {
        A_Clipboard := clipboardHistory[clipboardHistory.Length]
    }
    
    ClipWait(0.3)
    Send("^v")
    Sleep(100)
    
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(100)
    
    isFormatting := false
}
