; Mouse and Keyboard features

UpdateNumLockState()
UpdateNumLockState() {
    SetNumLockState(alwaysNumLockEnabled ? "AlwaysOn" : "Default")
}

#HotIf mouseClickEnabled
RAlt::Click()         
RCtrl::Click("Right") 
#HotIf


