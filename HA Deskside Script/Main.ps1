# Effectivley needed to overhaul the previous version because of how much stuff I was adding to very specific side scripts
function Get-Architecture {
	[CmdletBinding()]
	param ()
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture | Write-Output $Architecture.OSArchitecture
}
Get-Architecture
