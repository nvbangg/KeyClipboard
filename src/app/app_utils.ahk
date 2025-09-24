clearSettingsCache() {
    readSetting("__CLEAR_CACHE__", "", "")
}

clearSettingFromCache(section, key) {
    static settings := Map()
    fullKey := section . "_" . key
    if (settings.Has(fullKey))
        settings.Delete(fullKey)
}

cleanupGui(guiObj) {
    if IsObject(guiObj) {
        guiObj.Destroy()
        return 0
    }
    return guiObj
}

closeEvents(guiObj, closeCallback) {
    guiObj.OnEvent("Escape", closeCallback)
    guiObj.OnEvent("Close", closeCallback)
}

destroyGui(guiObj) {
    if (isGuiValid(guiObj)) {
        guiObj.Destroy()
        return true
    }
    return false
}

; Check if GUI object is valid and window still exists
isGuiValid(guiObj) {
    try {
        return IsObject(guiObj) && guiObj.HasProp("Hwnd") && WinExist("ahk_id " . guiObj.Hwnd)
    } catch {
        return false
    }
}

; Activate existing GUI window if valid
activateExistingGui(guiObj) {
    if (isGuiValid(guiObj)) {
        hwnd := guiObj.Hwnd
        WinActivate("ahk_id " . hwnd)  ; Bring window to front
        return true
    }
    return false
}

; Check if array contains a specific value
HasValue(arr, val) {
    for i, v in arr {
        if (v = val)
            return true
    }
    return false
}

; Join array elements with delimiter
Join(arr, delimiter) {
    result := ""
    for i, v in arr {
        if (i > 1)  ; Add delimiter before all except first element
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
        default: return 2  ; Default to 100
    }
}


