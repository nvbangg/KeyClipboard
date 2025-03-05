; Application features

#HotIf WinActive("ahk_exe chrome.exe")

; Translate page in Chrome
CapsLock & t:: {
    BlockInput("On")
    
    MouseClick("Right")
    Sleep(50)
    Send("t")
    Sleep(50)
    Send("{Enter}")
    Sleep(50) 
    MouseClick("Left")   
    
    BlockInput("Off")
}

#HotIf
