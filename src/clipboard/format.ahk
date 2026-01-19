formatDisplayText(text) {
    text := RegExReplace(text, "\r?\n\s*\r?\n", "  ↩↩  ")
    text := RegExReplace(text, "[\r\n]+", "  ↩  ")

    return text
}

formatText(text) {
    global removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    if (text = "")
        return ""

    if (removeAccentsEnabled)
        text := removeAccents(text)
    if (removeSpecialEnabled)
        text := removeSpecial(text)

    switch lineOption {
        case 1: text := removeEmptyLines(text)
        case 2: text := Trim(RegExReplace(text, "\R", " "))
    }
    switch caseOption {
        case 1: text := StrUpper(text)
        case 2: text := StrLower(text)
        case 3: text := TitleCase(text)
        case 4: text := SentenceCase(text)
    }
    switch separatorOption {
        case 1: text := normalizeSpaces(text)
        case 2: text := normalizeSpaces(text, "_")
        case 3: text := normalizeSpaces(text, "-")
        case 4: text := RegExReplace(text, "[ \t]+", "")
    }

    return text
}

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

removeAccents(str) {
    result := ""
    loop parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

normalizeSpaces(str, separator := " ") {
    str := RegExReplace(str, "(?m)^[ \t]+|[ \t]+$", "")
    str := RegExReplace(str, "[ \t]+", separator)
    return str
}

removeSpecial(str) {
    str := RegExReplace(str, "[^\p{L}\p{N}\s]", " ")
    return normalizeSpaces(str)
}

removeEmptyLines(str) {
    str := RegExReplace(str, "\R+", "`r`n")
    str := RegExReplace(str, "^\R+|\R+$", "")
    return str
}

TitleCase(str) {
    lines := StrSplit(str, "`n", "`r")
    result := ""
    for lineIdx, line in lines {
        if (lineIdx > 1)
            result .= "`n"
        lineResult := ""
        wordStart := true

        loop parse, line {
            if (A_LoopField = " " || A_LoopField = "-" || A_LoopField = "_") {
                lineResult .= A_LoopField
                wordStart := true
            } else {
                if (wordStart) {
                    lineResult .= StrUpper(A_LoopField)
                    wordStart := false
                } else {
                    lineResult .= StrLower(A_LoopField)
                }
            }
        }
        result .= lineResult
    }
    return result
}

SentenceCase(str) {
    str := StrLower(str)
    str := RegExReplace(str, "(^|[\.\!\?\r\n]+)(\s*)([a-z])", "$1$2$U3")
    str := RegExReplace(str, "(\" "|\')(\s*)([a-z])", "$1$2$U3")
    return str
}
