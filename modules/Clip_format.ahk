;Clip_format

; Format text according to current settings
formatText(text) {
    global formatCaseOption, formatSeparator, removeDiacriticsEnabled, lineBreakOption, removeExcessiveSpacesEnabled
    if (text = "")
        return ""

    ; Apply independent formatting options first
    if (removeDiacriticsEnabled)
        text := removeAccents(text)

    if (removeExcessiveSpacesEnabled)
        text := removeExcessiveSpaces(text)

    ; Apply line break formatting based on option
    switch lineBreakOption {
        case 1:  ; Remove excessive line breaks
            text := removeExcessiveLineBreaks(text)
        case 2:  ; Remove all line breaks
            text := removeLineBreaks(text)
    }

    ; Apply case formatting
    switch formatCaseOption {
        case 1:  ; UPPERCASE
            text := StrUpper(text)
        case 2:  ; lowercase
            text := StrLower(text)
        case 3:  ; Title Case
            text := TitleCase(text)
        case 4:  ; Sentence case
            text := SentenceCase(text)
    }

    ; Apply separator formatting
    switch formatSeparator {
        case 1:  ; Under_score
            text := StrReplace(text, " ", "_")
        case 2:  ; Hyphen-dash
            text := StrReplace(text, " ", "-")
        case 3:  ; Nospacing
            text := StrReplace(text, " ", "")
    }

    return text
}

removeExcessiveSpaces(str) {
    ; Trim leading spaces
    str := RegExReplace(str, "^\s+", "")
    loop {
        oldStr := str
        str := StrReplace(str, "  ", " ")
        if (str = oldStr)
            break
    }

    ; Remove spaces before punctuation
    punctuation := [".", ",", ";", ":"]
    for punct in punctuation {
        str := StrReplace(str, " " . punct, punct)
    }

    ; Ensure one space after punctuation (but not at the end of text)
    for punct in punctuation {
        pos := 1
        while (pos := InStr(str, punct, false, pos)) {
            if (pos = 0)
                break

            ; Check if it's not the end of the string
            if (pos < StrLen(str)) {
                nextChar := SubStr(str, pos + 1, 1)
                if (nextChar != " " && !InStr(".,;:", nextChar)) {
                    str := SubStr(str, 1, pos) . " " . SubStr(str, pos + 1)
                }
            }
            pos += 1
        }
    }

    return str
}

; Function to remove excessive line breaks (no empty lines)
removeExcessiveLineBreaks(str) {
    ; First normalize all line endings to `n` (for easier processing)
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

removeLineBreaks(str) {
    ; Replace various line break sequences with space
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

; Remove Vietnamese diacritical marks
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

; Convert string to non-accented version
removeAccents(str) {
    result := ""
    loop parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

; Convert text to Title Case format
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

; Convert text to Sentence case format (capitalizes first letter of each sentence)
SentenceCase(str) {
    ; First convert everything to lowercase
    str := StrLower(str)

    ; Normalize line endings to `n` for easier processing
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")

    ; Split into paragraphs
    paragraphs := StrSplit(str, "`n")

    ; Process each paragraph
    for i, paragraph in paragraphs {
        ; Skip empty paragraphs
        if (paragraph = "")
            continue

        ; Find first letter position (after any leading spaces)
        firstLetterPos := 0
        loop parse, paragraph {
            firstLetterPos++
            if RegExMatch(A_LoopField, "[a-z]") {
                ; Found the first letter, capitalize it
                paragraph := SubStr(paragraph, 1, firstLetterPos - 1) .
                StrUpper(A_LoopField) .
                SubStr(paragraph, firstLetterPos + 1)
                break
            }
        }

        ; Find sentence endings within paragraph
        sentenceEndings := [".", "!", "?"]

        for _, ending in sentenceEndings {
            pos := 1
            while (pos := InStr(paragraph, ending, false, pos)) {
                if (pos = 0 || pos = StrLen(paragraph))
                    break

                ; Check the next character after the punctuation
                nextPos := pos + 1

                ; If the next character is a space, we need to capitalize the character after that
                if (SubStr(paragraph, nextPos, 1) = " ") {
                    charPos := nextPos + 1

                    ; If there's a character after the space
                    if (charPos <= StrLen(paragraph)) {
                        nextChar := SubStr(paragraph, charPos, 1)

                        ; If it's a lowercase letter, capitalize it
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

        ; Update the paragraph in the array
        paragraphs[i] := paragraph
    }

    ; Combine paragraphs back with proper line endings
    result := ""
    for i, paragraph in paragraphs {
        if (i > 1)
            result .= "`r`n"
        result .= paragraph
    }

    return result
}
