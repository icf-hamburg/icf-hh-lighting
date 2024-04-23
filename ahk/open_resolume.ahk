#Requires AutoHotkey >=2.0
#SingleInstance Force

PATH := "C:\Program Files\Resolume Arena\Arena.exe"

SetTitleMatchMode 1  ; https://www.autohotkey.com/docs/v2/lib/SetTitleMatchMode.htm
ids := WinGetList("Resolume Arena")

if (ids.Length == 0) {
    Result := MsgBox("Resolume ist nicht offen. Jetzt starten?",,4)
    
    if (Result = "Yes")	{
    	Run(PATH)
    }
	
} else if (ids.Length == 1) {
	WinActivate(ids[1])
} else {
	MsgBox("Zu viele Resolume Fenster offen. Ich weiß nicht, was ich tuen soll.")
}
