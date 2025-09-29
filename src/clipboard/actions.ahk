deleteSelected(LV, clipGui := 0, useSaved := false) {
    global history, saved, historyViewer, savedViewer

    if (!isFocusedControl("SysListView32")) {
        Send("{Delete}")
        return
    }
    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    sortArray(selectedIndex, -1)
    clipTab := TabUtils.getTab(useSaved)
    for _, item in selectedIndex
        clipTab.RemoveAt(item)
    if (useSaved) {
        saved := clipTab
        saveSavedItems()
    } else
        history := clipTab
    updateLV(LV, "", useSaved)

    rowCount := LV.GetCount()
    if (rowCount > 0) {
        focusLastItem(LV, useSaved)
    } else {
        viewer := useSaved ? savedViewer : historyViewer
        if (viewer && viewer.HasProp("Value"))
            viewer.Value := ""
    }
}

clearClipboard(clipGui := 0, useSaved := false) {
    global history, saved, clipGuiInstance
    if (useSaved) {
        if (MsgBox("Confirm Clear all saved items?", "Confirm Clear all", "YesNo 262144") != "Yes")
            return
        saved := []
        saveSavedItems()
    } else {
        pinnedItems := []
        for _, item in history {
            if (!item.HasProp("pinned"))
                item.pinned := false
            if (item.pinned)
                pinnedItems.Push(item)
        }
        history := pinnedItems
    }

    destroyGui(clipGuiInstance)
    clipGuiInstance := 0
    showMsg("All " . TabUtils.getName(useSaved) . " have been cleared")
}

selectAllItems(LV) {
    global historyViewer, savedViewer, historyLV, savedLV
    if (!isValidGuiControl(LV, "GetNext") || LV.GetCount() == 0)
        return

    useSaved := (LV == savedLV)
    selectedIndex := getSelectedIndex(LV)

    try {
        if (selectedIndex.Length == LV.GetCount()) {
            LV.Modify(0, "-Select")
            viewer := useSaved ? savedViewer : historyViewer
            if (viewer && viewer.HasProp("Value"))
                viewer.Value := ""
        } else {
            if (!isFocusedControl("SysListView32"))
                LV.Focus()
            LV.Modify(0, "Select")
            updateViewer(useSaved)
        }
    } catch {
    }
}

saveContent(LV, clipGui, useSaved := false) {
    global historyViewer, savedViewer, historyLV, savedLV
    selectedItems := getSelectedIndex(LV)
    clipTab := TabUtils.getTab(useSaved)
    useSaved := (LV == savedLV)
    viewer := useSaved ? savedViewer : historyViewer
    newText := viewer.Value

    if (selectedItems.Length = 0) {
        if (Trim(newText) = "") {
            updateLV(LV, "", useSaved)
            return
        }
        TabUtils.addItem(clipTab, newText, useSaved)
        updateLVWithNewItem(LV, clipTab, useSaved, "New item created")
        return
    }

    if (selectedItems.Length > 1) {
        if (Trim(newText) = "") {
            updateLV(LV, "", useSaved)
            return
        }

        TabUtils.addItem(clipTab, newText, useSaved)
        updateLVWithNewItem(LV, clipTab, useSaved, "New item created")
        return
    }

    if (selectedItems.Length = 1 && selectedItems[1] > 0 && selectedItems[1] <= clipTab.Length) {
        if (useSaved) {
            clipTab[selectedItems[1]] := newText
        } else {
            clipTab[selectedItems[1]].text := newText
            clipTab[selectedItems[1]].original := newText
        }

        rowNum := 1
        loop LV.GetCount() {
            if (Integer(LV.GetText(rowNum, 1)) = selectedItems[1]) {
                processedText := formatDisplayText(newText)
                displayContent := StrLen(processedText) > 100 ?
                    SubStr(processedText, 1, 100) . "..." : processedText
                LV.Modify(rowNum, , selectedItems[1], displayContent)
                break
            }
            rowNum++
        }

        if (useSaved)
            saveSavedItems()
        showMsg("Changes saved")
        selectRowByIndex(LV, selectedItems[1], "Select Focus Vis")
        updateViewer(useSaved)
    }
    updateClipTabReference(clipTab, useSaved)
}

; Split selected items by lines and add as a new item
splitToLines(LV := 0) {
    global history
    selectedItems := getSelectedItems(LV, 0, false)
    if (!selectedItems)
        return

    addedCount := 0
    for _, item in selectedItems {
        lines := StrSplit(item.text, "`n", "`r")
        for _, line in lines {
            trimmedLine := Trim(line)
            if (trimmedLine != "") {
                history.Push({
                    text: trimmedLine,
                    original: trimmedLine,
                    pinned: false
                })
                addedCount++
            }
        }
    }

    if (LV) {
        updateLV(LV, "", false)
        rowCount := LV.GetCount()
        if (rowCount > 0 && addedCount > 0) {
            startRow := rowCount - addedCount + 1
            if (startRow < 1)
                startRow := 1

            newIndices := []
            loop addedCount {
                currentRow := startRow + A_Index - 1
                if (currentRow <= rowCount)
                    newIndices.Push(currentRow)
            }
            selectRows(LV, newIndices)
            LV.Modify(rowCount, "Focus Vis")
            updateViewer(false)
        }
    }
    showMsg(addedCount . " lines added to history")
}

saveToClipboard(LV := 0, formatTextEnable := false) {
    global history
    selectedItems := getSelectedItems(LV, 0, false)
    if (!selectedItems)
        return

    addedCount := 0
    for _, item in selectedItems {
        newText := formatTextEnable ? formatText(item.text) : item.text
        history.Push({
            text: newText,
            original: item.original,
            pinned: false
        })
        addedCount++
    }

    if (LV) {
        updateLV(LV, "", false)
        rowCount := LV.GetCount()
        if (rowCount > 0 && addedCount > 0) {
            startRow := rowCount - addedCount + 1
            if (startRow < 1)
                startRow := 1

            newIndices := []
            loop addedCount {
                currentRow := startRow + A_Index - 1
                if (currentRow <= rowCount)
                    newIndices.Push(currentRow)
            }
            selectRows(LV, newIndices)
            LV.Modify(rowCount, "Focus Vis")
            updateViewer(false)
        }
    }
    showMsg("Added to history")
}

replaceWithFormat(LV := 0) {
    global history
    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    for _, itemIndex in selectedIndex {
        if (itemIndex > 0 && itemIndex <= history.Length) {
            formattedText := formatText(history[itemIndex].text)
            history[itemIndex].text := formattedText
            history[itemIndex].original := formattedText
        }
    }

    if (LV) {
        updateLV(LV, "", false)
        selectRows(LV, selectedIndex)
        updateViewer(false)
    }
    showMsg("Replaced with formatted text")
}

addToTab(LV := 0, useSaved := false) {
    sourceAddTo := !useSaved
    selectedItems := getSelectedItems(LV, 0, sourceAddTo)
    if (!selectedItems)
        return

    clipTab := TabUtils.getTab(useSaved)
    for _, item in selectedItems
        TabUtils.addItem(clipTab, item.text, useSaved)

    updateClipTabReference(clipTab, useSaved)
    showMsg("Added to " . TabUtils.getName(useSaved))
}

moveSelectedItems(LV, direction, useSaved := false) {
    if (!isFocusedControl("SysListView32"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    clipTab := TabUtils.getTab(useSaved)
    if (!clipTab || clipTab.Length = 0)
        return

    sortedIndices := selectedIndex.Clone()
    sortArray(sortedIndices, direction > 0 ? -1 : 1)

    movableIndices := []
    for _, currentIndex in sortedIndices {
        targetIndex := currentIndex + direction
        if (targetIndex >= 1 && targetIndex <= clipTab.Length) {
            isTargetOccupied := false
            for _, otherIndex in selectedIndex {
                if (otherIndex = targetIndex && !hasValue(movableIndices, otherIndex)) {
                    isTargetOccupied := true
                    break
                }
            }
            if (!isTargetOccupied)
                movableIndices.Push(currentIndex)
        }
    }

    if (movableIndices.Length = 0)
        return

    newClipTab := []
    for i, item in clipTab
        newClipTab.Push(item)

    newSelectedIndices := []
    for _, currentIndex in movableIndices {
        targetIndex := currentIndex + direction

        temp := newClipTab[currentIndex]
        newClipTab[currentIndex] := newClipTab[targetIndex]
        newClipTab[targetIndex] := temp

        newSelectedIndices.Push(targetIndex)
    }

    for i, item in newClipTab
        clipTab[i] := item

    for _, originalIndex in selectedIndex
        if (!hasValue(movableIndices, originalIndex))
            newSelectedIndices.Push(originalIndex)

    sortArray(newSelectedIndices, 1)
    updateClipTabReference(clipTab, useSaved)
    updateLV(LV, "", useSaved)
    selectRows(LV, newSelectedIndices)

    updateViewer(useSaved)
}

filterItems(searchText := "", useSaved := false) {
    clipTab := TabUtils.getTab(useSaved)
    filteredItems := []
    searchTextLower := searchText = "" ? "" : StrLower(searchText)

    for index, item in clipTab {
        itemText := TabUtils.getText(item, useSaved)
        if (searchText = "" || (itemText && InStr(StrLower(itemText), searchTextLower))) {
            itemObj := { text: TabUtils.getText(item, useSaved), original: TabUtils.getText(item, useSaved),
                originalIndex: index }
            if (!useSaved && item.HasProp("pinned"))
                itemObj.pinned := item.pinned
            filteredItems.Push(itemObj)
        }
    }
    return filteredItems
}

search(searchCtrl, useSaved := false) {
    global historyLV, savedLV, historyViewer, savedViewer
    if (useSaved) {
        updateLV(savedLV, searchCtrl.Value, true)
        updateViewer(true)
    } else {
        updateLV(historyLV, searchCtrl.Value, false)
        updateViewer(false)
    }
}

setPinState(LV := 0, pinState := true) {
    global history
    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    for _, itemIndex in selectedIndex {
        if (itemIndex > 0 && itemIndex <= history.Length) {
            if (!history[itemIndex].HasProp("pinned"))
                history[itemIndex].pinned := false
            history[itemIndex].pinned := pinState
        }
    }

    if (LV) {
        updateLV(LV, "", false)
        selectRows(LV, selectedIndex)
        updateViewer(false)
    }
    showMsg(pinState ? "Items pinned" : "Items unpinned")
}

getPinState(selectedIndex) {
    global history
    if (selectedIndex.Length = 0)
        return "none"

    pinnedCount := 0
    unpinnedCount := 0

    for _, itemIndex in selectedIndex {
        if (itemIndex > 0 && itemIndex <= history.Length) {
            isPinned := history[itemIndex].HasProp("pinned") && history[itemIndex].pinned
            if (isPinned)
                pinnedCount++
            else
                unpinnedCount++
        }
    }

    if (pinnedCount > 0 && unpinnedCount > 0)
        return "mixed"
    else if (pinnedCount > 0)
        return "pinned"
    else
        return "unpinned"
}

deleteOthers(LV := 0, useSaved := false) {
    global history, saved
    if (!isValidGuiControl(LV, "GetNext"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    clipTab := TabUtils.getTab(useSaved)
    if (clipTab.Length = 0)
        return

    keepItems := []
    for _, index in selectedIndex {
        if (index > 0 && index <= clipTab.Length)
            keepItems.Push(clipTab[index])
    }

    if (useSaved) {
        saved := keepItems
        saveSavedItems()
    } else
        history := keepItems

    if (LV) {
        updateLV(LV, "", useSaved)
        newIndices := []
        loop keepItems.Length
            newIndices.Push(A_Index)
        selectRows(LV, newIndices)
        updateViewer(useSaved)
    }
    showMsg("Other items deleted")
}

moveToBottom(LV := 0, useSaved := false) {
    if (!isFocusedControl("SysListView32"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    clipTab := TabUtils.getTab(useSaved)
    if (!clipTab || clipTab.Length = 0)
        return

    sortArray(selectedIndex, 1)
    selectedItems := []
    for _, index in selectedIndex {
        if (index > 0 && index <= clipTab.Length)
            selectedItems.Push(clipTab[index])
    }

    loop selectedIndex.Length {
        removeIndex := selectedIndex[selectedIndex.Length - A_Index + 1]
        if (removeIndex > 0 && removeIndex <= clipTab.Length)
            clipTab.RemoveAt(removeIndex)
    }

    for _, item in selectedItems
        clipTab.Push(item)

    updateClipTabReference(clipTab, useSaved)
    updateLV(LV, "", useSaved)

    newSelectedIndices := []
    startIndex := clipTab.Length - selectedItems.Length + 1
    loop selectedItems.Length
        newSelectedIndices.Push(startIndex + A_Index - 1)

    selectRows(LV, newSelectedIndices)
    updateViewer(useSaved)
    showMsg("Items moved to bottom")
}

moveToTop(LV := 0, useSaved := false) {
    if (!isFocusedControl("SysListView32"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    clipTab := TabUtils.getTab(useSaved)
    if (!clipTab || clipTab.Length = 0)
        return

    sortArray(selectedIndex, 1)
    selectedItems := []
    for _, index in selectedIndex {
        if (index > 0 && index <= clipTab.Length)
            selectedItems.Push(clipTab[index])
    }

    remainingItems := []
    for i, item in clipTab {
        isSelected := false
        for _, selectedIdx in selectedIndex {
            if (i = selectedIdx) {
                isSelected := true
                break
            }
        }
        if (!isSelected)
            remainingItems.Push(item)
    }

    clipTab.RemoveAt(1, clipTab.Length)
    for _, item in selectedItems
        clipTab.Push(item)
    for _, item in remainingItems
        clipTab.Push(item)

    updateClipTabReference(clipTab, useSaved)
    updateLV(LV, "", useSaved)

    newSelectedIndices := []
    loop selectedItems.Length
        newSelectedIndices.Push(A_Index)

    selectRows(LV, newSelectedIndices)
    updateViewer(useSaved)
    showMsg("Items moved to top")
}

reverseOrder(LV := 0, useSaved := false) {
    if (!isFocusedControl("SysListView32"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length < 2)
        return

    clipTab := TabUtils.getTab(useSaved)
    if (!clipTab || clipTab.Length = 0)
        return

    sortArray(selectedIndex, 1)
    selectedItems := []
    for _, index in selectedIndex {
        if (index > 0 && index <= clipTab.Length)
            selectedItems.Push(clipTab[index])
    }

    for i, index in selectedIndex {
        if (index > 0 && index <= clipTab.Length)
            clipTab[index] := selectedItems[selectedItems.Length - i + 1]
    }

    updateClipTabReference(clipTab, useSaved)
    updateLV(LV, "", useSaved)
    selectRows(LV, selectedIndex)
    updateViewer(useSaved)
    showMsg("Items reversed")
}

selectPinnedItems(LV) {
    global history, historyViewer
    if (!isValidGuiControl(LV, "GetNext") || LV.GetCount() == 0)
        return

    selectedIndex := getSelectedIndex(LV)
    pinnedIndices := []

    loop LV.GetCount() {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))
        if (itemIndex > 0 && itemIndex <= history.Length) {
            if (history[itemIndex].HasProp("pinned") && history[itemIndex].pinned)
                pinnedIndices.Push(itemIndex)
        }
    }

    if (pinnedIndices.Length = 0) {
        try {
            if (historyViewer && historyViewer.HasProp("Value"))
                historyViewer.Value := ""
        } catch {
        }
        return
    }

    allPinnedSelected := true
    for _, pinnedIndex in pinnedIndices {
        if (!hasValue(selectedIndex, pinnedIndex)) {
            allPinnedSelected := false
            break
        }
    }

    try {
        if (allPinnedSelected) {
            LV.Modify(0, "-Select")
            if (historyViewer && historyViewer.HasProp("Value"))
                historyViewer.Value := ""
        } else {
            if (!isFocusedControl("SysListView32"))
                LV.Focus()
            LV.Modify(0, "-Select")
            selectRows(LV, pinnedIndices, false)
            updateViewer(false)
        }
    } catch {
    }
}
