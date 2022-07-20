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
