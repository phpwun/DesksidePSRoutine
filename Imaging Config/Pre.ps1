# Part 1
# Somewhat self explanitory, find which USB drive conatains it then copies a folder to temp from a USB Drive
If (Test-Path E:)
    {
    Copy-Item -Path "E:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force
    }
else { Copy-Item -Path "D:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force }

# Begins a software installation via msiexec, specifies that it should wait till done to start the next cmdlet and then,
# supplies the installer path and that the installer should run as normal /I, and that it should run with no userinput /quietand specifies passthru so the output can be viewed if needed
#Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\copy 2 temp in C\Agent_Install_Heartland.MSI /quiet' -PassThru
#Write-Output "Agent_Install_Heartland."

# Same command as above without msiexe because this is not an msi installer, provides the silent argument differently.
Start-Process -Wait -FilePath 'C:\temp\copy 2 temp in C\Symantec Client.exe' -ArgumentList "/quiet" -PassThru
Write-Output "Finished." 

#Installs Chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)
Write-Output "Finished." 

# Part 2
#defines the architecture of the device as either 32 or 64 bit
function Get-Architecture {
	[CmdletBinding()]
	param ()
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Architecture.OSArchitecture
	Return $Architecture
}

#Uses the architecture defenition to find the dellcommandupdate executable and returns the file
function Get-DellCommandUpdateLocation {
$OvRide = $true
	$Architecture = Get-Architecture
	If ($Architecture -eq "32-bit" -Or $OvRide -eq "true") {
		$File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	} else {
		$File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	}
	Return $File.FullName
}

#Executes the functions and attempts to begin the update with the policy
$a=Get-DellCommandUpdateLocation
& $a /configure silent '-autoSuspendBitLocker=enable -userConsent=disable'
& $a /scan -outputLog='C:\dell\logs\scan.log'
& $a /applyUpdates -outputLog='C:\dell\logs\applyUpdates.log'

#Part 3
# Attributes the devices serial number to the defenition Name
$Name = (Get-WmiObject -class win32_bios).SerialNumber

# Attributes a custom string to the defenition Domain, this could be the domain server address
#$Domain = "cho.ha.local"

# Pipes Name and Domain into Add-Computer via NewName and DomainName to assign the device with,
# a name based off the serial number and a domain based off of the string defined above.
Remove-Item 'C:\Windows\System32\Recovery\ReAgent.xml' -Force -Confirm -Confirm:$false
Rename-Computer -NewName $Name


#Add-Computer -NewName $Name -DomainName $Domain -Restart -PassThru -Force -Credential User