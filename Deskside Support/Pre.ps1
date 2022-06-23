#Deskside CMDLT v.01

#Global Variables
    #Identifies if the device is #64 Bit or #32 Bit
    $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture

#Pre-requisite Functions
    #Locates Dell Command Update main exe and returns it
    function DCULocation ($OVRDell = $false) {
	    If ($Architecture.OSArchitecture -eq "32-bit" -Or $OVRDell -eq "true") {
		        $File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	        } else {
		        $File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	        }
	    Return $File.FullName
    }

#Actionable Functions
    #Copy or Delete Installer Folder into C:/temp
    function MTemp($Copy = $false) {
        iF ($Copy -eq "$true") {
            If (Test-Path E:) {
                Copy-Item -Path "E:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force
            }
            elseif (Test-Path D:) {
                Copy-Item -Path "D:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force 
            }
            }
            else {
            If (Test-Path E:) {
                Delete-File -Path "E:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force
            }
            elseif (Test-Path D:) {
                Delete-File -Path "D:\copy 2 temp in C" -Destination "C:\temp" -recurse -Force
            }
        }
    }
    #Clears all Non-Admin Users and Runs Disk Cleanup aswell as Defrag.
    function RoutineClear {

    }
    #Runs through the IT Post imaging checklist, minus domain assignment and setting default apps.
    function PostImage{ #Install Programs and Initiate DellCommandUpdate
        #Move Temp Folder
        MTemp $true
        #Symantec Install
        Start-Process -Wait -FilePath 'C:\temp\copy 2 temp in C\Symantec Client.exe' -ArgumentList "/quiet" -PassThru
        Write-Output "Finished Symantec Intallation."
        #Chrome (Will need to be swapped out when they stop serving this version link)
        $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)
        Write-Output "Finished Chrome Intallation." 
        #DellCommandUpdate
        $a=DCULocation $true
        & $a /configure silent '-autoSuspendBitLocker=enable -userConsent=disable'
        & $a /scan -outputLog='C:\dell\logs\scan.log'
        & $a /applyUpdates -outputLog='C:\dell\logs\applyUpdates.log'
        Rename-Computer -NewName (Get-WmiObject -class win32_bios).SerialNumber -Force -Passthru
        Remove-Item 'C:\Windows\System32\Recovery\ReAgent.xml' -Force -Confirm:$false
        Restart-Computer
    }
    #Assigns a csv list of service tags to the HA Laptops OU (Needs to be changed to be a modular OU)
    function ADOUChange{
        $laptops = Get-Content "Devices.csv"
            foreach ($laptop in $laptops) {
                $obj = Get-ADComputer $laptop
                Get-ADComputer $obj | Move-ADObject -TargetPath "OU=Laptops,OU=HA,OU=Heartland Alliance,OU=Systems,DC=cho,DC=ha,DC=local" -Verbose
            }
    }

function Show-Menu {
    Write-Host "1: Clear Users and Run Defragmentation and Disk Cleanup"
    Write-Host "2: Preform Post-Imaging Checklist (This option will restart the device)"
    Write-Host "3: Move a Group of Devices within AD"
    Write-Host "Q: Press 'Q' to quit."
}
do {
    Show-Menu
    $input = Read-Host "what do you want to do?"
    switch ($input)
    {
        '1' {               
                RoutineClear
            }
        '2' {
                PostImage
            }
        '3' {
                ADOUChange
            }
        'q' {
                 return
            }
    }
    pause
}
until ($input -eq 'q')