#Include clip_utils.ahk
#Include clip_format.ahk
#Include clip_storage.ahk
#Include clip_functions.ahk

global historyTab := []
global savedTab := []
global isProcessing := false
global originalClip := ""
global clipGuiInstance := 0
global savedFilePath := A_ScriptDir . "\data\saved.ini"

addFormatOptions(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h200", "Format Options")

    checkboxOptions := [
        ["removeAccentsEnabled", removeAccentsEnabled, "Remove Accents"],
        ["normSpaceEnabled", normSpaceEnabled, "Normalize Spaces"],
        ["removeSpecialEnabled", removeSpecialEnabled, "Remove Special Characters (# *)"]
    ]
    yPos += 25

    for option in checkboxOptions {
        settingsGui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    yPos += 10

    dropdownOptions := [
        ["Line Break:", "lineOption", ["None", "Trim Lines", "Remove All Line Breaks"], lineOption],
        ["Text Case:", "caseOption", ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"], caseOption],
        ["Word Separator:", "separatorOption", ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"],
        separatorOption]
    ]

    for option in dropdownOptions {
        settingsGui.Add("Text", "x20 y" . yPos . " w150", option[1])
        settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] .
        " Choose" . (option[4] + 1), option[3])
        yPos += 30
    }

    return yPos + 15
}

showClipboard() {
    global historyTab, savedTab, clipGuiInstance, historyLV, savedLV, historyViewer, savedViewer, tabs

    if (!checkClipInstance())
        return

    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")

    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)

    tabs.OnEvent("Change", onTabChange)

    buildTabUI(clipGui, tabs, false)
    buildTabUI(clipGui, tabs, true)

    ; tabs.UseTab() ; no need to call UseTab here

    clipGui.OnEvent("Close", (*) => clipGui.Destroy())
    clipGui.OnEvent("Escape", (*) => clipGui.Destroy())

    HotIfWinActive("ahk_id " . clipGui.Hwnd)

    enterHotkey(*) => execAction("enter", clipGui)
    altUpHotkey(*) => execAction("altUp", clipGui)
    altDownHotkey(*) => execAction("altDown", clipGui)
    ctrlAHotkey(*) => execAction("ctrlA", clipGui)
    deleteHotkey(*) => execAction("delete", clipGui)

    Hotkey "Enter", enterHotkey
    Hotkey "!Up", altUpHotkey
    Hotkey "!Down", altDownHotkey
    Hotkey "^a", ctrlAHotkey
    Hotkey "Delete", deleteHotkey
    HotIf()

    updateLV(historyLV, "", false)
    updateLV(savedLV, "", true)

    if (historyTab.Length > 0) {
        updateTabContent(1, clipGui.Hwnd)
    } else if (savedTab.Length > 0) {
        tabs.Value := 2
        updateTabContent(2, clipGui.Hwnd)
    }

    clipGui.Show("w720 h570")
}

showClipboardHelp(*) {
    helpText :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+A: Select all items in the list`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected item up/down in the list`n" .
        "• Right-click: Show context menu with more options`n`n"

    showInfo("Clipboard Help", helpText, 350)
}

showContextMenu(LV, clipGui, Item, X, Y, useSavedTab := false) {
    if (Item = 0)
        return

    global historyViewer, savedViewer
    contentViewer := useSavedTab ? savedViewer : historyViewer

    menuItems := [
        ["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSavedTab))],
        ["Paste with Format", (*) => (pasteSelected(LV, clipGui, 1, useSavedTab))],
        ["Paste as Original", (*) => (pasteSelected(LV, clipGui, -1, useSavedTab))]
    ]

    if (!useSavedTab) {
        menuItems.Push([])
        menuItems.Push(["Save to Saved Tab", (*) => (saveToSavedItems(LV))])
        menuItems.Push(["Save Format to Clipboard", (*) => (saveToClipboard(LV, true))])
    }

    menuItems.Push([])
    menuItems.Push(["Delete Item", (*) => deleteSelected(LV, clipGui, useSavedTab)])

    contextMenu := createContextMenu(menuItems)
    contextMenu.Show(X, Y)
}

buildTabUI(clipGui, tabs, useSavedTab) {
    global historyLV, savedLV, historyViewer, savedViewer

    tabs.UseTab(useSavedTab ? 2 : 1)
    selectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    clipGui.Add("Text", "x90 y40", "Search:")
    searchBox := clipGui.Add("Edit", "x150 y37 w560")

    listView := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    listView.ModifyCol(1, 50, "Integer")
    listView.ModifyCol(2, 640)

    contentViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll HScroll", "")

    if (!useSavedTab) {
        historyLV := listView
        historyViewer := contentViewer
    } else {
        savedLV := listView
        savedViewer := contentViewer
    }

    searchBox.OnEvent("Change", (*) => handleSearch(searchBox, useSavedTab))
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(listView, contentViewer))

    listView.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipGui, Item, X, Y, useSavedTab))

    listView.OnEvent("Click", (*) => updateContent(listView, contentViewer, useSavedTab))
    listView.OnEvent("ItemSelect", (*) => updateContent(listView, contentViewer, useSavedTab))
    listView.OnEvent("ItemFocus", (*) => updateContent(listView, contentViewer, useSavedTab))
    listView.OnEvent("DoubleClick", (*) => pasteSelected(listView, clipGui, 0, useSavedTab))

    actionBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(listView, contentViewer, clipGui, useSavedTab)],
        ["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, useSavedTab)],
        ["x410 y530 w120", "Help", (*) => showClipboardHelp()]
    ]

    for option in actionBtns
        clipGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])
}
