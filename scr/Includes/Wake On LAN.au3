#include-once
;The function to generate the WoL Magic Package
Func GenerateMagicPacket($strMACAddress)
	$MagicPacket = ""
	$MACData = ""
	For $p = 1 To 11 Step 2
		$MACData = $MACData & Chr(Dec(StringMid($strMACAddress, $p, 2)))
	Next
	For $p = 1 To 6
		$MagicPacket = Chr(Dec("ff")) & $MagicPacket
	Next
	For $p = 1 To 16
		$MagicPacket = $MagicPacket & $MACData
	Next
	Return $MagicPacket
EndFunc   ;==>GenerateMagicPacket
