#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=..\build\Opener.Exe
#AutoIt3Wrapper_Res_Fileversion=1.2.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#RequireAdmin
#include "Includes\Password.au3"
#include <Crypt.au3>
#include <Constants.au3>
#include <WinAPIShPath.au3>
#include <APIConstants.au3>
#include <WinAPIEx.au3>
#include <TrayConstants.au3>
#include "Includes\Config.au3"
#include "Includes\Updater.au3"

If $bAutoupdate Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe", True)
If @CPUArch = "X64" Then DllCall("kernel32.dll", "int", "Wow64RevertWow64FsRedirection", "int", 1) ;Solution for a error with the tscon command not being found in x64 (the executable is x86)

Global $bIsLocked

;Create the tray menu, only valid if the program is not a service.
Opt("TrayMenuMode", 1)
Opt("TrayOnEventMode", 1)
$idStart = TrayCreateItem("Run Opener when my conputer starts", -1, -1)
TrayItemSetOnEvent(-1, "ToggleStart")
$filename = StringRegExpReplace(@ScriptName, '(^.*).(.*)$', '1')
If FileExists(@StartupDir & $filename & '.lnk') Then TrayItemSetState(-1, $TRAY_CHECKED)
TrayCreateItem("Exit")
TrayItemSetOnEvent(-1, "ExitScript")
TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.
Func ToggleStart()
	If TrayItemGetState($idStart) = ($TRAY_ENABLE + $TRAY_CHECKED) Then
		;If Not FileExists(@StartupDir & $filename & '.lnk') Then FileCreateShortcut(@ScriptFullPath, @StartupDir & '' & $filename & '.lnk')
		If Not _TaskExists("ParsecShortcutOpener") Then _TaskCreate("ParsecShortcutOpener")
	Else
		;If FileExists(@StartupDir & $filename & '.lnk') Then FileDelete(@StartupDir & '' & $filename & '.lnk')
		_TaskDelete("ParsecShortcutOpener")
	EndIf
EndFunc   ;==>ToggleStart
Func ExitScript()
	Exit
EndFunc   ;==>ExitScript

Func _TaskExists($sTaskName)
	$DOS = Run('schtasks /query /fo CSV /nh', "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($DOS)
	$Message = StdoutRead($DOS)
	$aTaskList = StringSplit($Message,@CRLF,1)
	For $i=1 To UBound($aTaskList)-1
		If StringLeft($aTaskList[$i],9) = '"\'&$sTaskName&'"' Then
			Return 1
		EndIf
	Next
	Return 0
EndFunc
Func _TaskCreate($sTaskName)
	$result = RunWait ('schtasks /create /tn "'&$sTaskName&'" /tr "\"'&@ScriptFullPath&'\" -task 1" /sc ONSTART /rl HIGHEST', "", @SW_HIDE)
	If @error Or $result <> 0 Then MsgBox($MB_ICONERROR,"","ERROR: Can't create task."&@CRLF&"Error code: " & $result)
EndFunc
Func _TaskDelete($sTaskName)
	$result = RunWait ('schtasks /delete /tn "'&$sTaskName&'" /f', "", @SW_HIDE)
	If @error Or $result <> 0 Then MsgBox($MB_ICONERROR,"","ERROR: Can't delete task."&@CRLF&"Error code: " & $result)
EndFunc

If RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server", "fDenyTSConnections") And Not RegRead("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "AutoAdminLogon") Then
	Switch MsgBox(324,"","RDP is disabled on your system." & @CRLF & "RDP is used to control a computer remotely." & @CRLF & "We use it to unlock your computer (Parsec still can not control the login screen)." & @CRLF & "Do you want to enable RDP?")
		Case 6 ;Yes
			RegWrite("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server", "fDenyTSConnections","REG_DWORD", 0)
		Case 7 ;No
			Switch MsgBox(292,"","You do not want to enable RDP, so we could try another approach." & @CRLF & "We can have windows automatically enter a user when starting the computer." & @CRLF & "Do you want to enable autologon?")
				Case 6 ;Yes
					AutoLogon(InputBox("","Enter your username"), InputBox("","Enter your password","","*"))
				Case 7 ;No
					MsgBox(64,"","Parsec CAN'T control the logon screen yet, you need to ensure your computer will not be on this screen when use this program.")
			EndSwitch
	EndSwitch
EndIf
Func AutoLogon($sUsername, $sUserPassword = "");Write autologon information to registry
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "DefaultUserName", "REG_SZ", $sUsername)
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "DefaultPassword", "REG_SZ", $sUserPassword)
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "AutoAdminLogon", "REG_SZ", "1")
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "AutoLogonCount", "REG_DWORD", 1)
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "DefaultDomainName", "REG_SZ", @LogonDomain)
EndFunc ;==>AutoLogon
Func AutoLogonreset();Clear autologon
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "AutoAdminLogon", "REG_SZ", 0)
	RegWrite("HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinLogon\", "DefaultPassword", "REG_SZ", "")
EndFunc ;==>AutoLogonreset

TCPStartup() ; Start the TCP service.
OnAutoItExitRegister("OnAutoItExit") ; Register OnAutoItExit to be called when the script is closed.

;Crypto stuff
_Crypt_Startup() ;Start the Crypt functions
Global $g_hKey = _Crypt_DeriveKey($sGlobalPassword, $CALG_RC4) ;Generate a key (this password is keep a secret, you need to create a file in Includes\Password.au3 and add the line Global $sGlobalPassword = "yourkey")
OnAutoItExitRegister("_Crypt_Shutdown") ;Function the cleaning of the crypt library on program exit

;Read the config, the default ip 0.0.0.0 listens in all computer's IP
$aCmdLine = _WinAPI_CommandLineToArgv($CmdLineRaw) ;Read arguments
$sConfigFile = @WorkingDir&"\OpenerConfig.ini"
$sIPAddress = _ReadConfig($sConfigFile, "Opener", "IP", "Enter the IP address for the server", "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", Default, "0.0.0.0", Default, False)
$iPort = _ReadConfig($sConfigFile, "Opener", "Port", "Enter the port for the opener server, if not needed, enter 0", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 7999, Default, False)
$sPassword = _ReadConfig($sConfigFile, "Opener", "Password", "Enter the password for the opener server", Default, Default, Default, True)

;Save config to config file
IniWrite($sConfigFile, "Opener", "IP", $sIPAddress)
IniWrite($sConfigFile, "Opener", "Port", $iPort)
Local $bEncrypted = _Crypt_EncryptData($sPassword, $g_hKey, $CALG_USERKEY) ;Encrypt password
IniWrite($sConfigFile, "Opener", "Password", $bEncrypted) ;Write encrypted password to config file
_DeleteConfigCrypt()
OnAutoItExitUnRegister("_DeleteConfigCrypt")

Global $g_hOpenerKey = _Crypt_DeriveKey($sPassword, $CALG_RC4) ;Generate a key
OnAutoItExitRegister("_CloseCrypt") ;Program the cleaning of the crypt library on program exit

#include "Includes\Opener\SessionState.au3"

; Assign a Local variable the socket and bind to the IP Address and Port specified with a maximum of 2 pending connexions, could be 1, but meh
Global $iListenSocket = TCPListen($sIPAddress, $iPort, 2)
If @error Then
	; Someone is probably already listening on this IP Address and Port (script already running?).
	MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "Could not listen, Error code: " & @error & @CRLF & "The program will now exit.")
	Exit
EndIf

Func _DeleteConfigCrypt()
	_Crypt_DestroyKey($g_hKey)
EndFunc
Func _CloseCrypt()
	_Crypt_DestroyKey($g_hOpenerKey)
EndFunc   ;==>_CloseCrypt


While 1
	_ServerLoop()
WEnd

Func _ServerLoop()
	$iSocket = 0
	$hTimer = TimerInit()
	Do ; Wait for someone to connect (Unlimited).
		Sleep(10) ;Give the CPU a rest.
		; Accept incomming connexions if present (Socket to close when finished; one socket per client).
		$iSocket = TCPAccept($iListenSocket)
		;If no user is connected, check for updates every 5 minutes
		If TimerDiff($hTimer) > 5*60*1000 Then
			If $bAutoupdate Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe", True)
		EndIf
		; If an error occurred display the error code and exit.
		If @error Then
			MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "Could not accept the incoming connection, Error code: " & @error & @CRLF & "The program will now exit.")
			Exit
		EndIf
	Until $iSocket <> -1 ;if different from -1 a client is connected.
	;Check update everytime a user connects
	Local $sReceived = TCPRecv($iSocket, 2048) ; Assign a Local variable the data received we're waiting for the string.
	_AnalyseReceivedData($sReceived, $iSocket)
	TCPCloseSocket($iSocket) ; Close the socket.
EndFunc

Func _AnalyseReceivedData($sData, $iSocket)
	$sData = BinaryToString(_Crypt_DecryptData($sData, $g_hOpenerKey, $CALG_USERKEY))
	If @error Then
		TCPSend($iSocket, "BPW") ;Inform about incorrect password
	Else
		If Not StringInStr($sData, @CR) Then Return
		$aData = StringSplit($sData,@CR)
		$sData = $aData[2]
		$iVersion = $aData[1]
		If $iVersion <> $iProtocolVersion Then
			TCPSend($iSocket, "BPV") ;Inform about incorrect protocol version
			MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "" & @CRLF & "The program will now exit and try to update.", 5)
			Exit
		Else
			Switch StringLeft($sData, 3)
				Case "URL" ;Run and Url are the same for now
					ShellExecute(StringTrimLeft($sData, 3))
					TCPSend($iSocket, "RDY")
					If $bAutoupdate Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe", True)
					Exit
				Case "RUN" ;Run and Url are the same for now
					ShellExecute(StringTrimLeft($sData, 3))
					TCPSend($iSocket, "RDY")
					If $bAutoupdate Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe", True)
					Exit
				Case "PNG" ;Ping
					TCPSend($iSocket, "PNG")
				Case "RDP" ;RDP related commands, only valid is RDPCLOSE
					$iUserID = _LoggedUserID(StringTrimLeft($sData, 8))
					If Not @error Then
						If StringLeft(StringTrimLeft($sData, 3),5) = "CLOSE" Then
							RunWait(@ComSpec & " /c " & 'tscon '&$iUserID&' /dest:console', "", @SW_HIDE)
							TCPSend($iSocket, "RDY")
						Else
							TCPSend($iSocket, "BCM") ;Inform about incorrect command
						EndIf
					Else
						TCPSend($iSocket, "ERR")
					EndIf
				Case "RBT" ;Reboot
					TCPSend($iSocket, "RDY")
					Shutdown(6) ; Force a reboot
				Case "CLS" ;Exit
					TCPSend($iSocket, "RDY")
					Exit
				Case "SSS" ;Send Session State
					TCPSend($iSocket, "SS"&Number($bIsLocked))
				Case "OPC" ;Open Parsec Client
					If Not ProcessExists("client.exe") Then
						Run(@AppDataDir&"\Parsec\client.exe")
						TCPSend($iSocket, "RDY")
					Else
						TCPSend($iSocket, "RNG") ;Already running
					EndIf
				Case Else ;Bad Command
					TCPSend($iSocket, "BCM") ;Inform about incorrect command
			EndSwitch
		EndIf
	EndIf
EndFunc   ;==>_AnalyseReceivedData

Func _IsLocked()
	Local $fIsLocked = False
	Local Const $hDesktop = _WinAPI_OpenDesktop('Default', $DESKTOP_SWITCHDESKTOP)
	If @error = 0 Then
		$fIsLocked = Not _WinAPI_SwitchDesktop($hDesktop)
		_WinAPI_CloseDesktop($hDesktop)
	EndIf
	Return $fIsLocked
EndFunc ;==>_IsLocked

Func _LoggedUserID($sUsername)
	;@error = 1 -> No user logged in, we are at login screen
	;@error = 2 -> User not found, the user doesn't exists or in not logged in
	$DOS = Run('query user', "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($DOS)
	$Message = StdoutRead($DOS)
	If $Message = "" Then
		Return SetError(1, 0, -1)
	Else
		$aUserList = StringSplit($Message,@CRLF,1)
		For $i=2 To UBound($aUserList)-1
			$aUserList[$i] = StringRegExpReplace($aUserList[$i], "(\s{2,})", @TAB)
			$aUserInfo = StringSplit($aUserList[$i],@TAB,1)
			If $aUserInfo[1] = ">"&$sUsername Then Return $aUserInfo[3]
		Next
		;Didn't find the User, let's try to see if there is only one user logged in, if there is one, use that user.
		If $aUserList[0] = 3 And $aUserList[3] = "" Then
			$aUserInfo = StringSplit($aUserList[2],@TAB,1)
			Return $aUserInfo[3]
		EndIf
	EndIf
	Return SetError(2,0,-1)
EndFunc

Func OnAutoItExit()
	; Close the Listening socket to allow afterward binds.
	TCPCloseSocket($iListenSocket)
	; Close the TCP service.
	TCPShutdown()
EndFunc   ;==>OnAutoItExit