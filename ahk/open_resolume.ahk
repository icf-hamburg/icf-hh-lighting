#Requires AutoHotkey >=2.0
#SingleInstance Force

SetTitleMatchMode 1  ; https://www.autohotkey.com/docs/v2/lib/SetTitleMatchMode.htm

PromptAndOpenResolume() {
    Result := MsgBox("Resolume ist nicht offen. Jetzt starten?",,4)
    if (Result = "Yes")	{
    	Run("C:\Program Files\Resolume Arena\Arena.exe")
    }
}

GetActiveWindow() {
    return WinGetTitle("A")
}


IsResolumeActive() {
    return InStr(GetActiveWindow(), "Resolume Arena") 
}
IsMa3Active() {
    return RegExMatch(GetActiveWindow(), "Display \d onPC")
}

GetOpenResolumeWindows() {
    return WinGetList("ahk_exe Arena.exe")
}

GetOpenMa3Windows() {
    return WinGetList("ahk_exe app_gma3.exe")
}


FocusTargetWindow() {
    if IsMa3Active() {
        return GetOpenResolumeWindows()
    }
    else {
        return GetOpenMa3Windows()
    }
}

if (GetOpenResolumeWindows().Length == 0) {
    PromptAndOpenResolume()
} else {
    for window in FocusTargetWindow()
        WinActivate(window)
}
