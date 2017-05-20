#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Crypt.au3>
#include <WinAPIShPath.au3>
#include <TrayConstants.au3>
#include "Includes\Config.au3"
#include "Includes\Updater.au3"
If @Compiled Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe")

Opt("TrayMenuMode", 1)
Opt("TrayOnEventMode", 1)
; Create a tray item with the radio item parameter selected.
$idStart = TrayCreateItem("Run Opener when my conputer starts", -1, -1)
TrayItemSetOnEvent(-1, "ToggleStart")
$filename = StringRegExpReplace(@ScriptName, '(^.*).(.*)$', '1')
If FileExists(@StartupDir & $filename & '.lnk') Then TrayItemSetState(-1, $TRAY_CHECKED)
TrayCreateItem("Exit")
TrayItemSetOnEvent(-1, "ExitScript")
TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.
Func ToggleStart()
	If TrayItemGetState($idStart) = ($TRAY_ENABLE + $TRAY_CHECKED) Then
		If Not FileExists(@StartupDir & $filename & '.lnk') Then FileCreateShortcut(@ScriptFullPath, @StartupDir & '' & $filename & '.lnk')
	Else
		If FileExists(@StartupDir & $filename & '.lnk') Then FileDelete(@StartupDir & '' & $filename & '.lnk')
	EndIf
EndFunc   ;==>ToggleStart
Func ExitScript()
	Exit
EndFunc   ;==>ExitScript

TCPStartup() ; Start the TCP service.
; Register OnAutoItExit to be called when the script is closed.
OnAutoItExitRegister("OnAutoItExit")

;Read the config, the default ip 0.0.0.0 listens in all computer's IP
$aCmdLine = _WinAPI_CommandLineToArgv($CmdLineRaw) ;Read arguments
$sConfigFile = @AppDataCommonDir & "OpenerConfig.ini"
$sIPAddress = _ReadConfig($sConfigFile, "Opener", "IP", "Enter the IP address for the server", "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", Default, "0.0.0.0", Default, False)
$iPort = _ReadConfig($sConfigFile, "Opener", "Port", "Enter the port for the opener server, if not needed, enter 0", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 7999, Default, False)
$sPassword = _ReadConfig($sConfigFile, "Opener", "Password", "Enter the password for the opener server", Default, Default, Default, True)

;Save config to config file
IniWrite($sConfigFile, "Opener", "IP", $sIPAddress)
IniWrite($sConfigFile, "Opener", "Port", $iPort)
IniWrite($sConfigFile, "Opener", "Password", $sPassword)

;Crypto stuff
_Crypt_Startup() ;Start the Crypt functions
$g_hKey = _Crypt_DeriveKey($sPassword, $CALG_RC4) ;Generate a key (this password should be keep a secret)
OnAutoItExitRegister("_CloseCrypt") ;Program the cleaning of the crypt library on program exit
Func _CloseCrypt()
	;Close, destroy and clean all the Crypt functions
	_Crypt_DestroyKey($g_hKey)
	_Crypt_Shutdown()
EndFunc   ;==>_CloseCrypt

; Assign a Local variable the socket and bind to the IP Address and Port specified with a maximum of 2 pending connexions, could be 1, but meh
Local $iListenSocket = TCPListen($sIPAddress, $iPort, 2)
If @error Then
	; Someone is probably already listening on this IP Address and Port (script already running?).
	MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "Could not listen, Error code: " & @error & @CRLF & "The program will now exit.")
	Exit
EndIf
While 1
	$iSocket = 0
	Do ; Wait for someone to connect (Unlimited).
		; Accept incomming connexions if present (Socket to close when finished; one socket per client).
		$iSocket = TCPAccept($iListenSocket)
		; If an error occurred display the error code and exit.
		If @error Then
			MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "Could not accept the incoming connection, Error code: " & @error & @CRLF & "The program will now exit.")
			Exit
		EndIf
	Until $iSocket <> -1 ;if different from -1 a client is connected.
	;Check update everytime a user connects
	If @Compiled Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/OpenerVersion", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Opener.exe")
	; Assign a Local variable the data received.
	Local $sReceived = TCPRecv($iSocket, 2048) ;we're waiting for the string "tata" OR "toto" (example script TCPRecv): 4 bytes length.
	; Notes: If you don't know how much length will be the data,
	; use e.g: 2048 for maxlen parameter and call the function until the it returns nothing/error.
	; Display the string received.
	_AnalyseReceivedData($sReceived)
	; Close the socket.
	TCPCloseSocket($iSocket)
WEnd

Func _AnalyseReceivedData($sData)
	$sData = BinaryToString(_Crypt_DecryptData($sData, $g_hKey, $CALG_USERKEY))
	If Not StringInStr($sData, @CR) Then Return
	$aData = StringSplit($sData,@CR)
	$sData = $aData[2]
	$iVersion = $aData[1]
	If $iVersion <> $iProtocolVersion Then
		MsgBox($MB_ICONERROR, "", "Opener:" & @CRLF & "" & @CRLF & "The program will now exit to update", 5)
		Exit
	Else
		Switch StringLeft($sData, 3)
			Case "URL"
				ShellExecute(StringTrimLeft($sData, 3))
			Case "RUN"
				ShellExecute(StringTrimLeft($sData, 3))
			Case "ACC"
			Case "PSC"
			Case "RBT"
				Shutdown(6) ; Force a reboot
		EndSwitch
	EndIf
EndFunc   ;==>_AnalyseReceivedData

Func OnAutoItExit()
	; Close the Listening socket to allow afterward binds.
	TCPCloseSocket($iListenSocket)
	; Close the TCP service.
	TCPShutdown()
EndFunc   ;==>OnAutoItExit
