#include-once
#include <InetConstants.au3>
#include <File.au3>
Global $hUpdateDownload, $sTempFile = _TempFile(), $sTempUpdaterFile = _TempFile() & ".bat", $iDownloadState = 0, $bAlwaysRunning = False

$bAutoupdate = Number(_ReadConfig(@WorkingDir&"\Config.ini", 'Updater', 'Autoupdate', "", "(.*)", "", @Compiled, False, False))

Func _Update($sCurrentVersion, $sVersionUrl, $sUrl, $bIsAR = False)
	If $bAutoupdate Then
		$sUpdatedVersion = BinaryToString(InetRead($sVersionUrl, $INET_FORCERELOAD))
		If $sCurrentVersion <> $sUpdatedVersion Then
			$bAlwaysRunning = $bIsAR
			$hUpdateDownload = InetGet($sUrl, $sTempFile, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
			OnAutoItExitRegister("StopExitUntilFinishDownload")
			$iDownloadState = 1
			AdlibRegister("CheckUpdateDownload")
			Return True
		Else
			$iDownloadState = 0
			Return False
		EndIf
	EndIf
EndFunc   ;==>_Update
Func CheckUpdateDownload()
	If InetGetInfo($hUpdateDownload, $INET_DOWNLOADCOMPLETE) Then
		AdlibUnRegister("CheckUpdateDownload")
		FileWriteLine($sTempUpdaterFile, "@echo off")
		;The bat will wait until the program terminates
		FileWriteLine($sTempUpdaterFile, ':waitforpid')
		FileWriteLine($sTempUpdaterFile, 'tasklist /fi "pid eq '&@AutoItPID&'" 2>nul | find "'&@AutoItPID&'" >nul')
		FileWriteLine($sTempUpdaterFile, 'if %ERRORLEVEL%==0 (')
		FileWriteLine($sTempUpdaterFile, '  timeout /t 2 /nobreak >nul')
		FileWriteLine($sTempUpdaterFile, '  goto :waitforpid')
		FileWriteLine($sTempUpdaterFile, ')')
		;then update the exe
		FileWriteLine($sTempUpdaterFile, 'timeout /t 2 /nobreak >nul')
		;FileWriteLine($sTempUpdaterFile, 'START CMD /C "ECHO My Popup Message && PAUSE"')
		FileWriteLine($sTempUpdaterFile, 'del "' & @ScriptFullPath & '" &&')
		FileWriteLine($sTempUpdaterFile, 'move "' & $sTempFile & '" "' & @ScriptFullPath & '" &&')
		;If always running, run the program after update
		If $bAlwaysRunning Then FileWriteLine($sTempUpdaterFile, 'START "' & @ScriptFullPath & '" &&')
		;and delete itself
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