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

resolume_id_string := "Resolume Arena"
ma3_id_string := "Display"

IsResolumeActive() {
    return InStr(GetActiveWindow(), resolume_id_string) 
}
IsMa3Active() {
    return InStr(GetActiveWindow(), ma3_id_string)
}

GetOpenResolumeWindows() {
    return WinGetList(resolume_id_string)
}

GetOpenMa3Windows() {
    return WinGetList(ma3_id_string)
}


FocusTargetWindow() {
    if IsMa3Active() {
        return GetOpenResolumeWindows()[1]
    }
    else {
        return GetOpenMa3Windows()[1]
    }
}

if (GetOpenResolumeWindows().Length == 0) {
    PromptAndOpenResolume()
} else {
    WinActivate(FocusTargetWindow())
}
