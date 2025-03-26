loadSavedItems() {
    global savedTab
    existFile(savedFilePath)

    try {
        fileContent := FileRead(savedFilePath)
        if (fileContent = "")
            return

        lines := StrSplit(fileContent, "`n", "`r")
        savedTab := []

        for _, line in lines {
            if (line = "")
                continue

            decodedText := decodeLine(line)
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
        for _, item in savedTab {
            if (!item || !item.HasProp("text") || item.text = "")
                continue

            encodedLine := encodeLine(item.text)
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

    loop length // 4 {
        charCode := "0x" . SubStr(encodedLine, (A_Index - 1) * 4 + 1, 4)
        result .= Chr(Integer(charCode))
    }

    return result
}
