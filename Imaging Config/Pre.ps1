#Global Functions

function Get-Architecture { #64 Bit or #32 Bit
	[CmdletBinding()]
	param ()
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Architecture.OSArchitecture
	Return $Architecture
}

function Get-DellCommandUpdateLocation { #Find DellCommandUpdate Exe
    $OvRide = $true
	$Architecture = Get-Architecture
	If ($Architecture -eq "32-bit" -Or $OvRide -eq "true") {
		$File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	} else {
		$File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	}
	Return $File.FullName
}

function MTemp { #Move Installer Folder To Temp
    If (Test-Path E:)
        {
        Copy-Item -Path "E:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force
        }
    else { Copy-Item -Path "D:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force }
}

function Main{ #Install Programs and Initiate DellCommandUpdate
    #Move Folder To Temp
    MTemp

    #Symantec
    Start-Process -Wait -FilePath 'C:\temp\copy 2 temp in C\Symantec Client.exe' -ArgumentList "/quiet" -PassThru
    Write-Output "Finished Symantec Intallation."

    #Chrome
    $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)
    Write-Output "Finished Chrome Intallation." 


    #DellCommandUpdate
    $a=Get-DellCommandUpdateLocation
    & $a /configure silent '-autoSuspendBitLocker=enable -userConsent=disable'
    & $a /scan -outputLog='C:\dell\logs\scan.log'
    & $a /applyUpdates -outputLog='C:\dell\logs\applyUpdates.log'
}

#Runtime Function
function FinishUp {
    param ([string]$Name)
    Main
    Rename-Computer -NewName $Name -Force -Passthru
    Remove-Item 'C:\Windows\System32\Recovery\ReAgent.xml' -Force -Confirm:$false
    Restart-Computer
}


FinishUp (Get-WmiObject -class win32_bios).SerialNumber