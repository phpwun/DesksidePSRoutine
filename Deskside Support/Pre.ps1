#Deskside CMDLT v.01

#Global Variables
    #Identifies if the device is #64 Bit or #32 Bit
    $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture

#Pre-requisite Functions
    #Locates Dell Command Update Executable
    function DCULocation ($OVRDell = $false) {
	    If ($Architecture.OSArchitecture -eq "32-bit" -Or $OVRDell -eq "true") {
		        $File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	        } else {
		        $File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	        }
	    Return $File.FullName
    }
    function AcceptFile($type, $where) {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath($where)
        Filter = $type
        }
    $null = $FileBrowser.ShowDialog()
    return $FileBrowser.FileName
    }
    #Displays A List of Options for the User
    function Show-Menu {
        Write-Host "
        1: Clear Users and Run Defragmentation and Disk Cleanup
        2: Preform Post-Imaging Checklist (Add to domain and bitlocker after reboot)
        3: Move a Group of Devices within AD
        Q: Press 'Q' to quit."
    }

#Actionable Functions
    #Clears all Non-Admin Users and Runs Disk Cleanup aswell as Defrag.
    function RoutineClear { #Source: https://stackoverflow.com/questions/28852786/automate-process-of-disk-cleanup-cleanmgr-exe-without-user-intervention
      Write-Host 'Clearing CleanMgr Settings and Enabling Extra CleanUp'
        Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name StateFlags0001 -ErrorAction SilentlyContinue | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
      Write-Host 'Starting.'
        Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1 /verylowdisk /AUTOCLEAN' -WindowStyle Hidden -Wait
      Write-Host 'Waiting for CleanMgr and DismHost processes. Second wait neccesary as CleanMgr.exe spins off separate processes.'
        Get-Process -Name cleanmgr,dismhost -ErrorAction SilentlyContinue | Wait-Process
      Write-Host 'Defragmentation Begining.'
        Optimize-Volume -DriveLetter C -ReTrim -Verbose
        Optimize-Volume -DriveLetter C -Defrag -Verbose

      $UpdateCleanupSuccessful = $false
      if (Test-Path $env:SystemRoot\Logs\CBS\DeepClean.log) {
          $UpdateCleanupSuccessful = Select-String -Path $env:SystemRoot\Logs\CBS\DeepClean.log -Pattern 'Total size of superseded packages:' -Quiet
      }

      if ($UpdateCleanupSuccessful) {
          Write-Host 'Rebooting.'
          SHUTDOWN.EXE /r /f /t 0 /c
      }
    }
    #Runs through the IT Post imaging checklist, minus domain assignment and setting default apps.
    function PostImage{ #Install Programs and Initiate DellCommandUpdate

        #Chrome (Will need to be swapped out when they stop serving this version link)
        $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)
        Write-Output "Finished Chrome Intallation."

        #DellCommandUpdate
        $a=DCULocation $true; & $a /configure silent '-autoSuspendBitLocker=enable -userConsent=disable'; & $a /scan -outputLog='C:\dell\logs\scan.log'; & $a /applyUpdates -outputLog='C:\dell\logs\applyUpdates.log'

        #Hopefully adding device to domain
        $cred = Get-credential
        $SerialName = (Get-WmiObject -class win32_bios).SerialNumber
        $Parameters = @{
            "DomainName" = "cho.ha.local"
            "NewName" = $SerialName
            "Credential" = "$cred"
            "Server" = "cho.ha.local\20816DC02"
            "OUPath" = "OU=*New Computers,DC=cho,DC=ha,DC=local"
            "Restart" = $false
            "Force" = $true
        }
        Add-Computer $Parameters

        #Bitlocker Pre-Emptive
        Remove-Item 'C:\Windows\System32\Recovery\ReAgent.xml' -Force -Confirm:$false

        #Finishing Up
        #Write-Output 'After Reboot Ensure that you join the device to the cho.ha.local network, reboot again and enable bitlocker.'
        #Restart-Computer
    }
    #Assigns a csv list of service tags to the HA Laptops OU (Needs to be changed to be a modular OU)
    function ADOUChange{
        $Where = Read-Host "Please Enter OU Path: (HA, HAI, HH, HHCS, HHO)"
        $What = Read-Host "Please Enter Device List Type: (Laptops, Desktops)"
        $filety = 'Comma Seperated Values (*.csv)|*.csv'; $location = 'Desktop'; $File = AcceptFile $filety $location
        $laptops = Get-Content $File
                foreach ($laptop in $laptops) {
                    $obj = Get-ADComputer $laptop
                    Get-ADComputer $obj | Move-ADObject -TargetPath "OU=$What,OU=$Where,OU=Heartland Alliance,OU=Systems,DC=cho,DC=ha,DC=local" -Verbose
                }
    }
do {
    Show-Menu
    $input = Read-Host
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
