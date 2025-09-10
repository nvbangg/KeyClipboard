loadSavedItems() {
    global savedTab
    existFile(savedFilePath)

    try {
        fileContent := FileRead(savedFilePath)
        if (fileContent = "")
            return

        lines := StrSplit(fileContent, "`n", "`r")
        savedTab := []

        ; Process each line from file
        for _, line in lines {
            if (line = "")
                continue

            decodedText := decodeLine(line)  ; Decode hex back to text
            if (decodedText != "") {
                savedTab.Push({
                    text: decodedText,
                    original: decodedText
                })
            }
        }
    } catch Error as err {
        showNotification("Error reading data: " . err.Message)
    }
}

saveSavedItems() {
    global savedTab

    existFile(savedFilePath)

    try {
        fileContent := ""
        ; Process each saved item
        for _, item in savedTab {
            if (!item || !item.HasProp("text") || item.text = "")
                continue

            encodedLine := encodeLine(item.text)  ; Encode text as hex
            if (encodedLine != "")
                fileContent .= encodedLine . "`n"
        }

        if (FileExist(savedFilePath))
            FileDelete(savedFilePath)
        FileAppend(fileContent, savedFilePath)
    } catch Error as err {
        showNotification("Error saving data: " . err.Message)
    }
}

; Encode text as hex values to safely store in file
encodeLine(text) {
    if (text = "")
        return ""

    encoded := ""
    ; Convert each character to 4-digit hex
    for i, char in StrSplit(text) {
        encoded .= Format("{:04X}", Ord(char))
    }

    return encoded
}

; Decode hex values back to original text
decodeLine(encodedLine) {
    if (encodedLine = "")
        return ""

    result := ""
    length := StrLen(encodedLine)

    ; Process 4-character hex chunks
    loop length // 4 {
        charCode := "0x" . SubStr(encodedLine, (A_Index - 1) * 4 + 1, 4)
        result .= Chr(Integer(charCode))  ; Convert hex back to character
    }

    return result
}
