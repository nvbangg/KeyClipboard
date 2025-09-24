class TabUtils {
    static getTab(useSaved) {
        global history, saved
        return useSaved ? saved : history
    }

    static getText(item, useSaved) {
        if (useSaved)
            return IsObject(item) ? (item.HasProp("text") ? item.text : String(item)) : item
        else
            return IsObject(item) ? item.text : item
    }

    static getName(useSaved) {
        return useSaved ? "Saved" : "History"
    }

    static addItem(clipTab, text, useSaved) {
        if (useSaved)
            clipTab.Push(text)
        else
            clipTab.Push({ text: text, original: text, pinned: false })
    }

    static pasteItem(item, formatMode, useSaved) {
        if (formatMode == -1) {
            if (IsObject(item) && item.HasProp("original"))
                paste(item.original)
            else
                paste(TabUtils.getText(item, useSaved))
        } else {
            paste(TabUtils.getText(item, useSaved), formatMode)
        }
    }

    static getItemAtPosition(clipTab, index, useSaved) {
        return useSaved ? clipTab[index] : clipTab[clipTab.Length - index + 1]
    }
}