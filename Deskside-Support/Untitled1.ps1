#Invoke-WebRequest -Uri https://raw.githubusercontent.com/thomasmaurer/demo-cloudshell/master/helloworld.ps1 -OutFile .\helloworld.ps1; .\helloworld.ps1 
$user=(Get-WmiObject -Class win32_computersystem).UserName.split('\')[1]
Invoke-WebRequest 'https://github.com/phpwun/DesksidePSRoutine.git' -OutFile "c:\users\$user\Downloads"
Expand-Archive "c:\users\$user\Downloads\DesksidePSRoutine.zip"
