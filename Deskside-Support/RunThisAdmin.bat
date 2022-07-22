Dism.exe /online /import-defaultappassociations:%~dp0Dependencies\CustomFileAssoc.xml
powershell -ep Bypass %~dp0Dependencies\Pre.ps1
pause
