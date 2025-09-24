AddCheckboxGroup(gui, yPos, options) {
    for option in options {
        gui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    return yPos + 10
}

AddDropdownGroup(gui, yPos, options) {
    for option in options {
        gui.Add("Text", "x20 y" . yPos . " w150", option[1])
        gui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] . " Choose" . (
            option[4] + 1), option[3])
        yPos += 30
    }
    return yPos
}

showMsg(message, timeout := 1300) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")  ; Borderless, always on top
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")  ; Show without stealing focus
    SetTimer(() => notify.Destroy(), -timeout)
}