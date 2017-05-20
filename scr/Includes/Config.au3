#include-once
#include <Crypt.au3>
$iProtocolVersion = 2
;Read the config, first search the arguments, then the config file and last ask the user
Global $g_hKey, $aCmdLine = []
Func _ReadConfig($sConfigFile, $sSection, $sKey, $sMessage, $sPattern = "(.*)", $sErrorMessage = "There was an error on the input, please try again.", $sDefault = "", $bIsPass = False, $bAskUser = True)
	;Default is... default
	If $sPattern = Default Then $sPattern = "(.*)"
	If $sErrorMessage = Default Then $sErrorMessage = "There was an error on the input, please try again."
	If $sDefault = Default Then $sDefault = ""
	If $bIsPass = Default Then $bIsPass = False
	If $bAskUser = Default Then $bAskUser = True
	$sReturn = _SearchCmdLine("-" & $sSection & "-" & $sKey)
	If $sReturn = '' Then ;If the param isn't in the arguments, read the config file
		;Read the config file (a random is used because some user could choose "ERROR" as his password o computer name)
		$iRandom = Random(10000, 99999, 1)
		$sReturn = IniRead($sConfigFile, $sSection, $sKey, "ERROR" & $iRandom & "ERROR")
		;If can´t find the key in Config.ini (file not exist or key doesn't exist) ask the user for the data
		If $sReturn = "ERROR" & $iRandom & "ERROR" Then
			If $bAskUser Then
				$sReturn = InputBox("", $sMessage, $sDefault, ($bIsPass ? "*" : ""))
				If @error Then ;Return SetError(1, 0, "ERROR") ; If the user press cancel in the inputbox
					MsgBox(16, '', 'Exiting...', 3)
					Exit
				EndIf
			Else
				$sReturn = $sDefault
			EndIf
		Else ;If there is a value stored, check if is encrypted
			If $bIsPass Then
				$sReturn = BinaryToString(_Crypt_DecryptData($sReturn, $g_hKey, $CALG_USERKEY))
			EndIf
		EndIf
	EndIf
	;If the data didn't pass a Regular Expression test, show a error message and ask again (used to validate IP addresses, MAC, email, etc)
	While Not StringRegExp($sReturn, $sPattern)
		MsgBox(16, "", $sErrorMessage)
		$sReturn = InputBox("", $sMessage, $sReturn, ($bIsPass ? "*" : ""))
		If @error Then ;Return SetError(1, 0, "ERROR") ; If the user press cancel in the inputbox
			MsgBox(16, '', 'Exiting...', 3)
			Exit
		EndIf
	WEnd
	;If all good, return the data
	Return $sReturn
EndFunc   ;==>_ReadConfig
;Search the arguments for a parameter. The arguments are in the format -name value, if you need spaces in the value, use double quotes.
Func _SearchCmdLine($sKey)
	Local $sReturn = ''
	If @Compiled Then ;Only compiled could have arguments
		;Search in the command line arguments the parameter
		For $i = 1 To UBound($aCmdLine) - 1 Step 2
			If $aCmdLine[$i] = $sKey Then
				$sReturn = $aCmdLine[$i + 1]
				ExitLoop
			EndIf
		Next
	EndIf
	Return $sReturn
EndFunc   ;==>_SearchCmdLine
Func _RequestServerList($cookies)
	;Request servers list from Parsec.tv
	$sLoadingText = "Getting servers list"
	$oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	ObjEvent($oHTTP, 'Evt_')
	$oHTTP.Open("POST", "https://parsec.tv/v1/server-list/?include_managed=true&format=json", False)
	$oHTTP.SetRequestHeader("Cookie", $cookies)
	$oHTTP.Send()
	$sResponse = $oHTTP.ResponseText
	Return $sResponse
EndFunc   ;==>_RequestServerList
Func _AnalyzeServerList($serversInfo, $sServerName)
	;Read server response and get the list of servers
	$sLoadingText = "Analysing servers list"
	$aServerData = StringRegExp($serversInfo, '{(.[^{}]*)}', 3)
	For $j = 0 To UBound($aServerData) - 1
		$sInstanceIDProp = -1
		$sNameProp = ''
		$aData = StringRegExp($aServerData[$j], '"(.[^"]*)": ?"(.[^"]*)"', 4)
		;Search for the name and instance_id
		For $i = 0 To UBound($aData) - 1
			$asPropiedades = $aData[$i]
			If $asPropiedades[1] = "name" Then
				$sNameProp = $asPropiedades[2]
			ElseIf $asPropiedades[1] = "instance_id" Then
				$sInstanceIDProp = $asPropiedades[2]
			EndIf
		Next
		;If the server name is the same that the server that we are waiting, we save the instance_id and continue
		If $sNameProp = $sServerName Then
			$sInstanceID = $sInstanceIDProp
			ExitLoop
		EndIf
	Next
	Return $sInstanceID
EndFunc   ;==>_AnalyzeServerList
