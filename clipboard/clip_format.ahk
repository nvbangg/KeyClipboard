formatText(text) {
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    if (text = "")
        return ""

    if (removeSpecialEnabled)
        text := removeSpecial(text)
    if (removeAccentsEnabled)
        text := removeAccents(text)
    if (normSpaceEnabled)
        text := normSpace(text)

    switch lineOption {
        case 1: text := trimLines(text)
        case 2: text := removeLineBreaks(text)
    }
    switch caseOption {
        case 1: text := StrUpper(text)
        case 2: text := StrLower(text)
        case 3: text := TitleCase(text)
        case 4: text := SentenceCase(text)
    }
    switch separatorOption {
        case 1: text := StrReplace(text, " ", "_")
        case 2: text := StrReplace(text, " ", "-")
        case 3: text := StrReplace(text, " ", "")
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

normSpace(str) {
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")

    str := RegExReplace(str, "[ \t]+", " ")
    str := RegExReplace(str, "(^|\n)[ \t]+", "$1")
    str := RegExReplace(str, " ([.,;:])", "$1")
    str := RegExReplace(str, "([.,;:])([^ \n.,;:])", "$1 $2")

    return str
}

removeSpecial(str) {
    str := StrReplace(str, "#", "")
    str := StrReplace(str, "*", "")
    return str
}

trimLines(str) {
    str := RegExReplace(str, "\R+", "`r`n")
    str := RegExReplace(str, "^\R+|\R+$", "")
    return str
}

removeLineBreaks(str) {
    str := RegExReplace(str, "\R", " ")
    str := RegExReplace(str, "[ \t]+", " ")
    return str
}

TitleCase(str) {
    words := StrSplit(str, [" ", "-", "_"], " `t")
    result := ""

    for i, word in words {
        if (word = "")
            continue

        firstChar := SubStr(word, 1, 1)
        restChars := SubStr(word, 2)

        if (i > 1)
            result .= A_Space

        result .= StrUpper(firstChar) . StrLower(restChars)
    }

    return result
}

SentenceCase(str) {
    str := StrLower(str)
    str := RegExReplace(str, "(^|[\.\!\?\r\n]+)(\s*)([a-z])", "$1$2$U3")
    str := RegExReplace(str, "(\" "|\')(\s*)([a-z])", "$1$2$U3")
    return str
}
