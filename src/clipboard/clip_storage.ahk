loadSavedItems() {
    global saved
    existFile(savedFilePath)

    try {
        fileContent := FileRead(savedFilePath)
        if (fileContent = "")
            return

        lines := StrSplit(fileContent, "`n", "`r")
        saved := []
        for _, line in lines {
            if (line = "")
                continue
            decodedText := decodeLine(line)
            if (decodedText != "") {
                saved.Push(decodedText)
            }
        }
    } catch Error as e {
        MsgBox("Error reading data: " . e.Message, "Error", "OK 262144")
    }
}

saveSavedItems() {
    global saved
    existFile(savedFilePath)

    try {
        fileContent := ""
        for _, item in saved {
            if (!item || item = "") 
                continue
            encodedLine := encodeLine(item)  ; item is now a string
            if (encodedLine != "")
                fileContent .= encodedLine . "`n"
        }

        if (FileExist(savedFilePath))
            FileDelete(savedFilePath)
        FileAppend(fileContent, savedFilePath)
    } catch Error as e {
        MsgBox("Error saving data: " . e.Message, "Error", "OK 262144")
    }
}

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
