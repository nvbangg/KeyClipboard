#Include clip_utils.ahk
#Include clip_format.ahk
#Include clip_storage.ahk
#Include clip_functions.ahk
global historyTab := []             ; Stores clipboard history items
global savedTab := []               ; Stores clipboard saved items
global isFormatting := false        ; Flag for formatting in progress
global originalClip := ""           ; Stores original clipboard content
global clipGuiInstance := 0  ; Reference to clipboard history GUI
global savedFilePath := A_ScriptDir . "\data\saved.ini"

addClipSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h200", "Format Options")

    ; Add checkboxes
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

    ; Add dropdown controls
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

; Create tab content for either History or Saved tab
createTabContent(clipGui, tabs, tabNumber, isHistoryTab) {
    global historyLV, savedLV, historyViewer, savedViewer

    tabs.UseTab(tabNumber)

    ; Add Select All button and search box
    selectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    clipGui.Add("Text", "x90 y40", "Search:")
    searchBox := clipGui.Add("Edit", "x150 y37 w560")

    ; Create ListView for items
    listView := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    listView.ModifyCol(1, 50, "Integer")
    listView.ModifyCol(2, 640)

    ; Store references to controls based on tab
    contentViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll HScroll", "")

    ; Store appropriate references and set event handlers based on tab type
    if (isHistoryTab) {
        historyLV := listView
        historyViewer := contentViewer
    } else {
        savedLV := listView
        savedViewer := contentViewer
    }

    ; Set tabType value TRƯỚC khi sử dụng nó trong các event handler
    tabType := !isHistoryTab

    ; Common event handler setup with proper parameters - sử dụng handleSearch
    searchBox.OnEvent("Change", (*) => handleSearch(searchBox, isHistoryTab))
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(listView, contentViewer))

    ; Fix context menu handler
    listView.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipGui, Item, X, Y, tabType))

    ; Stronger event handlers for selection
    listView.OnEvent("Click", (*) => updateContent(listView, contentViewer, tabType))
    listView.OnEvent("ItemSelect", (*) => updateContent(listView, contentViewer, tabType))
    listView.OnEvent("ItemFocus", (*) => updateContent(listView, contentViewer, tabType))
    listView.OnEvent("DoubleClick", (*) => pasteSelected(listView, clipGui, 0, tabType))

    actionBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(listView, contentViewer, clipGui, tabType)],
        ["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, tabType)],
        ["x410 y530 w120", "Help", (*) => showClipboardHelp()]
    ]

    for option in actionBtns
        clipGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])
}
handleTabAction(action, clipGui) {
    elements := getActiveTabElements(tabs)

    if (action = "enter") {
        if (isListViewFocused())
            pasteSelected(elements.listView, clipGui, 0, elements.isSaved)
        else
            Send("{Enter}")
    }
    else if (action = "altUp")
        moveSelectedItem(elements.listView, elements.contentViewer, -1, elements.isSaved)
    else if (action = "altDown")
        moveSelectedItem(elements.listView, elements.contentViewer, 1, elements.isSaved)
    else if (action = "ctrlA")
        selectAllItems(elements.listView, elements.contentViewer)
    else if (action = "delete")
        deleteSelected(elements.listView, clipGui, elements.isSaved)
}
showClipboard() {
    global historyTab, savedTab, clipGuiInstance, historyLV, savedLV, historyViewer, savedViewer, tabs

    ; Check if clipboard is empty or close existing instance
    if (!checkClipboardInstance())
        return

    ; Always create GUI since we've verified there's at least one item
    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")

    ; Add tabs for History and Saved with equal width
    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)  ; TCM_SETMINTABWIDTH = 0x1329

    ; Add tab change event handler to reload data
    tabs.OnEvent("Change", onTabChange)

    ; Create the tab content using the shared function
    createTabContent(clipGui, tabs, 1, true)   ; History tab
    createTabContent(clipGui, tabs, 2, false)  ; Saved tab

    ; Reset to first tab
    tabs.UseTab()

    clipGui.OnEvent("Close", (*) => clipGui.Destroy())
    clipGui.OnEvent("Escape", (*) => clipGui.Destroy())

    ; Special hotkeys when clipboard history is active
    HotIfWinActive("ahk_id " . clipGui.Hwnd)

    enterHotkey(*) => handleTabAction("enter", clipGui)
    altUpHotkey(*) => handleTabAction("altUp", clipGui)
    altDownHotkey(*) => handleTabAction("altDown", clipGui)
    ctrlAHotkey(*) => handleTabAction("ctrlA", clipGui)
    deleteHotkey(*) => handleTabAction("delete", clipGui)

    ; Assign the hotkeys to their functions
    Hotkey "Enter", enterHotkey
    Hotkey "!Up", altUpHotkey
    Hotkey "!Down", altDownHotkey
    Hotkey "^a", ctrlAHotkey
    Hotkey "Delete", deleteHotkey
    HotIf()

    ; Update both ListViews
    updateLV(historyLV, "", false) ; false = clipboard tab
    updateLV(savedLV, "", true)    ; true = saved items tab

    ; Set initial tab based on content availability
    if (historyTab.Length > 0) {
        ; Update history tab content and focus
        updateTabContent(1, clipGui.Hwnd)
    } else if (savedTab.Length > 0) {
        tabs.Value := 2  ; Switch to Saved tab
        ; Update saved tab content and focus
        updateTabContent(2, clipGui.Hwnd)
    }

    clipGui.Show("w720 h570")
}

; Show clipboard usage instructions
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

    ; Let the createInfoDialog function calculate proper button position
    createInfoDialog("Clipboard Help", helpText, 350)
}

; Context menu for clipboard and saved items
showContextMenu(LV, clipGui, Item, X, Y, useSavedTab := false) {
    if (Item = 0)
        return

    global historyViewer, savedViewer
    contentViewer := useSavedTab ? savedViewer : historyViewer

    ; Create menu items array
    menuItems := [
        ["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSavedTab))],
        ["Paste with Format", (*) => (pasteSelected(LV, clipGui, 1, useSavedTab))],
        ["Paste as Original", (*) => (pasteSelected(LV, clipGui, -1, useSavedTab))]
    ]

    ; Only add these items for clipboard tab (not saved tab)
    if (!useSavedTab) {
        menuItems.Push([]) ; Add separator
        menuItems.Push(["Save to Saved Tab", (*) => (saveToSavedItems(LV))])
        menuItems.Push(["Save Format to Clipboard", (*) => (saveToClipboard(LV, true))])
    }

    menuItems.Push([]) ; Add separator
    menuItems.Push(["Delete Item", (*) => deleteSelected(LV, clipGui, useSavedTab)])

    ; Create and show the menu
    contextMenu := createContextMenu(menuItems)
    contextMenu.Show(X, Y)
}
