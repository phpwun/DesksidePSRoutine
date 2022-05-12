# Part 1
# Somewhat self explanitory, copies a folder to temp from a USB Drive
Copy-Item -Path "D:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force

# Begins a software installation via msiexec, specifies that it should wait till done to start the next cmdlet and then,
# supplies the installer path and that the installer should run as normal /I, and that it should run with no userinput /quietand specifies passthru so the output can be viewed if needed
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\(Remote Software Name Goes Here).MSI /quiet' -PassThru
Write-Output "Finished."

# Same command as above without msiexe because this is not an msi installer, provides the silent argument differently.
Start-Process -Wait -FilePath 'C:\temp\(Remote Software Name 2 Goes Here).exe' -ArgumentList "/quiet" -PassThru
Write-Output "Finished." 

#Installs Chrome
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe" -OutFile "C:\temp\copy 2 temp in C\ChromeStandaloneSetup64.exe"; & -Wait "C:\temp\copy 2 temp in C\ChromeStandaloneSetup64.exe" /silent /install

# Part 2
#defines the architecture of the device as either 32 or 64 bit
function Get-Architecture {
	
	[CmdletBinding()]
	param ()
	
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Architecture.OSArchitecture
	#Returns 32-bit or 64-bit
	Return $Architecture
}

#Uses the architecture defenition to find the dellcommandupdate executable and returns the file
function Get-DellCommandUpdateLocation {
	
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
& $a /configure silent -autoSuspendBitLocker=enable -userConsent=disable
& $a /scan -outputLog='C:\dell\logs\scan.log'
& $a /applyUpdates -outputLog='C:\dell\logs\applyUpdates.log'

#Part 3
# Attributes the devices serial number to the defenition Name
$Name = (Get-WmiObject -class win32_bios).SerialNumber

# Attributes a custom string to the defenition Domain, this could be the domain server address
$Domain = "Domain.Goes.Here"

# Pipes Name and Domain into Add-Computer via NewName and DomainName to assign the device with,
# a name based off the serial number and a domain based off of the string defined above.
Add-Computer -NewName $Name -DomainName $Domain -Restart -PassThru -Force -Credential User