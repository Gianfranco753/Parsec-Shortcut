#include-once
#include <InetConstants.au3>
#include <File.au3>
Global $hUpdateDownload, $sTempFile = _TempFile(), $sTempUpdaterFile = _TempFile() & ".bat", $iDownloadState = 0
Func _Update($sCurrentVersion, $sVersionUrl, $sUrl)
	$sUpdatedVersion = InetRead($sVersionUrl, $INET_FORCERELOAD)
	If $sCurrentVersion <> $sUpdatedVersion Then
		$hUpdateDownload = InetGet($sUrl, $sTempFile, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		OnAutoItExitRegister("StopExitUntilFinishDownload")
		$iDownloadState = 1
		AdlibRegister("CheckUpdateDownload")
		Return True
	Else
		$iDownloadState = 0
		Return False
	EndIf
EndFunc   ;==>_Update
Func CheckUpdateDownload()
	If InetGetInfo($hUpdateDownload, $INET_DOWNLOADCOMPLETE) Then
		AdlibUnRegister("CheckUpdateDownload")
		FileWriteLine($sTempUpdaterFile, "@echo off")
		;The bat will wait until the program terminates
		FileWriteLine($sTempUpdaterFile, ":loop")
		FileWriteLine($sTempUpdaterFile, "tasklist /fi " & '"pid eq ' & @AutoItPID & '" | find ":" > nul') ;batch file won't continue until old autoit exe process id terminates
		FileWriteLine($sTempUpdaterFile, "if errorlevel 1 (")
		FileWriteLine($sTempUpdaterFile, "  timeout 1")
		FileWriteLine($sTempUpdaterFile, "  goto loop")
		FileWriteLine($sTempUpdaterFile, ") else (")
		FileWriteLine($sTempUpdaterFile, "  goto continue")
		FileWriteLine($sTempUpdaterFile, ")")
		FileWriteLine($sTempUpdaterFile, ":continue")
		;then update the exe
		FileWriteLine($sTempUpdaterFile, 'del "' & @ScriptFullPath & '"')
		FileWriteLine($sTempUpdaterFile, 'move "' & $sTempFile & '" "' & @ScriptFullPath & '"')
		FileWriteLine($sTempUpdaterFile, '(goto) 2>nul & del "%~f0"')
		Run($sTempUpdaterFile, @ScriptDir, @SW_HIDE) ;launch batch file in hidden mode
		$iDownloadState = 2
	EndIf
EndFunc   ;==>CheckUpdateDownload
Func StopExitUntilFinishDownload()
	If $iDownloadState = 1 Then
		Do
			Sleep(10)
		Until $iDownloadState = 2
	EndIf
EndFunc