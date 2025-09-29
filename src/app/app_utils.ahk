closeEvents(guiObj, closeCallback) {
    guiObj.OnEvent("Escape", closeCallback)
    guiObj.OnEvent("Close", closeCallback)
}

destroyGui(guiObj) {
    if (isGuiValid(guiObj))
        guiObj.Destroy()
}

isGuiValid(guiObj) {
    try {
        return IsObject(guiObj) && guiObj.HasProp("Hwnd") && WinExist("ahk_id " . guiObj.Hwnd)
    } catch {
        return false
    }
}

activateExistingGui(guiObj) {
    if (isGuiValid(guiObj)) {
        hwnd := guiObj.Hwnd
        WinActivate("ahk_id " . hwnd)
        return true
    }
    return false
}

hasValue(arr, val) {
    for i, v in arr
        if (v = val)
            return true
    return false
}

join(arr, delimiter) {
    result := ""
    for i, v in arr {
        if (i > 1)
            result .= delimiter
        result .= v
    }
    return result
}

getHistoryLimit(value) {
    switch value {
        case 50: return 1
        case 100: return 2
        case 200: return 3
        case 500: return 4
        case 1000: return 5
        default: return 2
    }
}
