#Include src\app\app.ahk
#Include src\clipboard\clipboard.ahk
#Include src\UI\UI.ahk

global dataDir := A_ScriptDir . "\data"
global settingsFilePath := A_ScriptDir . "\data\config.ini"
global savedFilePath := A_ScriptDir . "\data\savedHistory.ini"
global historyTab := []        
global savedTab := []          

; Application state
global isProcessing := false    ; Prevents clipboard loops during paste operations
global originalClip := ""       ; Backup of original clipboard content
global clipGuiInstance := 0     ; Reference to clipboard UI window
global contentViewerIsFocused := false

initSettings()
initCapsLockMonitor()
initClipboard()

; Check for command-line parameter to open settings
if (A_Args.Length > 0 && A_Args[1] = "settings") {
    SetTimer(showSettings, -200)
}

; CapsLock behavior: single press toggles caps, hold + key = shortcut
*CapsLock::
{
    KeyWait "CapsLock"
    if (A_PriorKey = "CapsLock" && A_ThisHotkey = "*CapsLock") {
        Sleep(20)
        if GetKeyState("CapsLock", "T")
            SetCapsLockState "AlwaysOff"
        else
            SetCapsLockState "AlwaysOn"
    }
}

; All shortcuts require holding CapsLock + another key
#HotIf GetKeyState("CapsLock", "P")
s:: showSettings()
+s:: alwaysOnTop()
Tab & s:: switchTabPreset()     ; Cycle to next preset in the list
!s:: switchTabPreset()
e:: showSettings()
+e:: alwaysOnTop()
Tab & e:: switchTabPreset()     ; Cycle to next preset in the list
!e:: switchTabPreset()
c:: showClipboard()
+c:: clearClipboard()
Tab & c:: showClipboard(true)   ; Open clipboard Saved tab
!c:: showClipboard(true)

; Format modes: 0=normal, 1=formatted, -1=original
; pastePrev(index, formatMode, useSavedTab)
v:: pastePrev(0)                ; Paste latest item
+v:: pastePrev(0, 1)            ; Paste latest item with format
^v:: pastePrev(0, -1)           ; Paste latest item as original
Tab & v:: pastePrev(0, 0, true) ; Paste latest item from saved tab
!v::  pastePrev(0, 0, true)

b:: pastePrev(1)                ; Paste the item before the latest
+b:: pastePrev(1, 1)            ; Paste the item before the latest with format
^b:: pastePrev(1, -1)           ; Paste the item before the latest as original
Tab & b:: pastePrev(1, 0, true) ; Paste the item before the latest from saved tab
!b:: pastePrev(1, 0, true)

a:: pasteSelected()             ; Paste all clipboard items
+a:: pasteSelected(, , 1)       ; Paste all clipboard items with format
^a:: pasteSelected(, , -1)      ; Paste all clipboard items as original
Tab & a:: pasteSelected(, , 0, true) ; Paste all saved items
!a:: pasteSelected(, , 0, true)

; pasteByIndex(index, formatMode, useSavedTab)
1:: pasteByIndex(1)                  ; Index 1 (latest) from clipboard history
+1:: pasteByIndex(1, 1)              ; Index 1 with formatting
^1:: pasteByIndex(1, -1)             ; Index 1 as original
Tab & 1:: pasteByIndex(1, 0, true)   ; Index 1 from saved tab
!1:: pasteByIndex(1, 0, true)

2:: pasteByIndex(2)                 
+2:: pasteByIndex(2, 1)             
^2:: pasteByIndex(2, -1)            
Tab & 2:: pasteByIndex(2, 0, true)   
!2:: pasteByIndex(2, 0, true)

3:: pasteByIndex(3)                 
+3:: pasteByIndex(3, 1)             
^3:: pasteByIndex(3, -1)            
Tab & 3:: pasteByIndex(3, 0, true)   
!3:: pasteByIndex(3, 0, true)

4:: pasteByIndex(4)                 
+4:: pasteByIndex(4, 1)             
^4:: pasteByIndex(4, -1)            
Tab & 4:: pasteByIndex(4, 0, true)   
!4:: pasteByIndex(4, 0, true)

5:: pasteByIndex(5)                 
+5:: pasteByIndex(5, 1)             
^5:: pasteByIndex(5, -1)            
Tab & 5:: pasteByIndex(5, 0, true)   
!5:: pasteByIndex(5, 0, true)

6:: pasteByIndex(6)                 
+6:: pasteByIndex(6, 1)             
^6:: pasteByIndex(6, -1)            
Tab & 6:: pasteByIndex(6, 0, true)   
!6:: pasteByIndex(6, 0, true)

7:: pasteByIndex(7)                 
+7:: pasteByIndex(7, 1)             
^7:: pasteByIndex(7, -1)            
Tab & 7:: pasteByIndex(7, 0, true)   
!7:: pasteByIndex(7, 0, true)

8:: pasteByIndex(8)                 
+8:: pasteByIndex(8, 1)             
^8:: pasteByIndex(8, -1)            
Tab & 8:: pasteByIndex(8, 0, true)   
!8:: pasteByIndex(8, 0, true)

9:: pasteByIndex(9)                 
+9:: pasteByIndex(9, 1)             
^9:: pasteByIndex(9, -1)            
Tab & 9:: pasteByIndex(9, 0, true)   
!9:: pasteByIndex(9, 0, true)

0:: pasteByIndex(10)                
+0:: pasteByIndex(10, 1)            
^0:: pasteByIndex(10, -1)           
Tab & 0:: pasteByIndex(10, 0, true) 
!0:: pasteByIndex(10, 0, true)

; pasteWithTab(formatMode, useSavedTab)
t:: pasteWithTab()                   ; Paste latest, tab, then second latest
+t:: pasteWithTab(1)                 ; Paste with formatting enabled
^t:: pasteWithTab(-1)                ; Paste as original text
Tab & t:: pasteWithTab(0, true)      ; Paste from saved tab
!t:: pasteWithTab(0, true)
f:: pasteWithBeforeLatest()          ; Paste "beforeLatest_latest"
+f:: pasteWithBeforeLatest(true)     ; Paste "beforeLatest_latest" (latest part formatted)

#HotIf