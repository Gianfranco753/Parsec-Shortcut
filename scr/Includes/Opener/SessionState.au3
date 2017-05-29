Global Const $NOTIFY_FOR_THIS_SESSION = 0x0
Global Const $NOTIFY_FOR_ALL_SESSIONS = 0x1
;Global Const $WM_WTSSESSION_CHANGE = 0x2B1

Global Const $WTS_CONSOLE_CONNECT = 0x1
Global Const $WTS_CONSOLE_DISCONNECT = 0x2
Global Const $WTS_REMOTE_CONNECT = 0x3
Global Const $WTS_REMOTE_DISCONNECT = 0x4
Global Const $WTS_SESSION_LOGON = 0x5
Global Const $WTS_SESSION_LOGOFF = 0x6
Global Const $WTS_SESSION_LOCK = 0x7
Global Const $WTS_SESSION_UNLOCK = 0x8
Global Const $WTS_SESSION_REMOTE_CONTROL = 0x9

;#include <WinAPIShPath.au3>
;#include "Includes\Config.au3"
;$aCmdLine = _WinAPI_CommandLineToArgv($CmdLineRaw) ;Read arguments
Global $bIsLocked = False
If _SearchCmdLine("-task") = "1" Then $bIsLocked = True

Global $hOpenerNotificationsGUI = GUICreate("Opener"); GUI to receive notification
GUISetState(@SW_HIDE)

GUIRegisterMsg($WM_WTSSESSION_CHANGE, "_WM_WTSSESSION_CHANGE")
DllCall("Wtsapi32.dll", "int", "WTSRegisterSessionNotification", "hwnd", $hOpenerNotificationsGUI, "dword", $NOTIFY_FOR_THIS_SESSION)
OnAutoItExitRegister("_NotificationUnregister")

Func _NotificationUnregister()
	DllCall("Wtsapi32.dll", "int", "WTSUnRegisterSessionNotification", "hwnd", $hOpenerNotificationsGUI)
EndFunc

Func _WM_WTSSESSION_CHANGE($hWnd, $iMsgID, $wParam, $lParam)
    ;$sMsg = @CRLF & @HOUR & ":" & @Min & ":" & @SEC & " = "
    Switch $wParam
        Case $WTS_CONSOLE_CONNECT
            ;$sMsg &= "A session was connected to the console terminal."
			$bIsLocked = True
        Case $WTS_CONSOLE_DISCONNECT
            ;$sMsg &= "A session was disconnected from the console terminal."
			$bIsLocked = True
        Case $WTS_REMOTE_CONNECT
            ;$sMsg &= "A session was connected to the remote terminal."
			$bIsLocked = True
        Case $WTS_REMOTE_DISCONNECT
            ;$sMsg &= "A session was disconnected from the remote terminal."
			$bIsLocked = True
        Case $WTS_SESSION_LOGON
            ;$sMsg &= "A user has logged on to the session."
			$bIsLocked = False
        Case $WTS_SESSION_LOGOFF
            ;$sMsg &= "A user has logged off the session."
			$bIsLocked = True
        Case $WTS_SESSION_LOCK
            ;$sMsg &= "A session has been locked."
			$bIsLocked = True
        Case $WTS_SESSION_UNLOCK
            ;$sMsg &= "A session has been unlocked."
			$bIsLocked = False
        Case $WTS_SESSION_REMOTE_CONTROL
            ;$sMsg &= "A session has changed its remote controlled status."
    EndSwitch
	;ConsoleWrite($sMsg&@CRLF)
EndFunc