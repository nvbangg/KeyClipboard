; Formats text according to user-defined settings
formatText(text) {
    global noAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineBreakOption, formatCaseOption, formatSeparator
    if (text = "")
        return ""

    ; Apply independent formatting options
    if (removeSpecialEnabled)
        text := removeSpecial(text)

    if (noAccentsEnabled)
        text := removeAccents(text)

    if (normSpaceEnabled)
        text := normSpace(text)

    ; Apply line break formatting
    switch lineBreakOption {
        case 1: text := trimLines(text)
        case 2: text := removeLineBreaks(text)
    }

    ; Apply case formatting
    switch formatCaseOption {
        case 1: text := StrUpper(text)
        case 2: text := StrLower(text)
        case 3: text := TitleCase(text)
        case 4: text := SentenceCase(text)
    }

    ; Apply separator formatting
    switch formatSeparator {
        case 1: text := StrReplace(text, " ", "_")
        case 2: text := StrReplace(text, " ", "-")
        case 3: text := StrReplace(text, " ", "")
    }

    return text
}

; Removes specified special characters (# and *)
removeSpecial(str) {
    str := StrReplace(str, "#", "")
    str := StrReplace(str, "*", "")
    return str
}

; Removes redundant spaces and fixes punctuation spacing
normSpace(str) {
    ; Split by line breaks to process each line
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")
    lines := StrSplit(str, "`n")

    ; Process each line individually
    for i, line in lines {
        ; Remove leading spaces from each line
        line := RegExReplace(line, "^\s+", "")

        ; Collapse multiple spaces to single space
        loop {
            oldLine := line
            line := StrReplace(line, "  ", " ")
            if (line = oldLine)
                break
        }

        ; Apply punctuation spacing rules
        punctuation := [".", ",", ";", ":"]

        ; Remove spaces before punctuation
        for punct in punctuation {
            line := StrReplace(line, " " . punct, punct)
        }

        ; Ensure one space after punctuation (except at end of text)
        for punct in punctuation {
            pos := 1
            while (pos := InStr(line, punct, false, pos)) {
                if (pos = 0)
                    break

                if (pos < StrLen(line)) {
                    nextChar := SubStr(line, pos + 1, 1)
                    if (nextChar != " " && !InStr(".,;:", nextChar)) {
                        line := SubStr(line, 1, pos) . " " . SubStr(line, pos + 1)
                    }
                }
                pos += 1
            }
        }

        ; Update the processed line
        lines[i] := line
    }

    ; Rejoin lines
    result := ""
    for i, line in lines {
        if (i > 1)
            result .= "`r`n"
        result .= line
    }

    return result
}

; Removes empty lines but preserves paragraph breaks
trimLines(str) {
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")
    lines := StrSplit(str, "`n")
    output := ""

    for i, line in lines {
        if (Trim(line) != "") {
            if (output != "")
                output .= "`n"
            output .= line
        }
    }

    return StrReplace(output, "`n", "`r`n")
}

; Converts all line breaks to spaces
removeLineBreaks(str) {
    str := StrReplace(str, "`r`n", " ")
    str := StrReplace(str, "`n", " ")
    str := StrReplace(str, "`r", " ")

    ; Replace multiple spaces with a single space
    loop {
        oldStr := str
        str := StrReplace(str, "  ", " ")
        if (str = oldStr)
            break
    }

    return str
}

; Mapping of accented characters to their non-accented equivalents
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

; Removes diacritical marks from text
removeAccents(str) {
    result := ""
    loop parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

; Capitalizes first letter of each word
TitleCase(str) {
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

; Capitalizes first letter of each sentence
SentenceCase(str) {
    str := StrLower(str)
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")
    paragraphs := StrSplit(str, "`n")

    for i, paragraph in paragraphs {
        if (paragraph = "")
            continue

        ; Capitalize first letter in paragraph
        firstLetterPos := 0
        loop parse, paragraph {
            firstLetterPos++
            if RegExMatch(A_LoopField, "[a-z]") {
                paragraph := SubStr(paragraph, 1, firstLetterPos - 1) .
                StrUpper(A_LoopField) .
                SubStr(paragraph, firstLetterPos + 1)
                break
            }
        }

        ; Find and capitalize letters after sentence endings
        sentenceEndings := [".", "!", "?"]

        for _, ending in sentenceEndings {
            pos := 1
            while (pos := InStr(paragraph, ending, false, pos)) {
                if (pos = 0 || pos = StrLen(paragraph))
                    break

                nextPos := pos + 1
                if (SubStr(paragraph, nextPos, 1) = " ") {
                    charPos := nextPos + 1
                    if (charPos <= StrLen(paragraph)) {
                        nextChar := SubStr(paragraph, charPos, 1)
                        if (RegExMatch(nextChar, "[a-z]")) {
                            paragraph := SubStr(paragraph, 1, charPos - 1) .
                            StrUpper(nextChar) .
                            SubStr(paragraph, charPos + 1)
                        }
                    }
                }
                pos += 1
            }
        }

        paragraphs[i] := paragraph
    }

    result := ""
    for i, paragraph in paragraphs {
        if (i > 1)
            result .= "`r`n"
        result .= paragraph
    }

    return result
}
