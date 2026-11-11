@echo off
setlocal
set "SELF=%~f0"
if "%SELF:~0,2%"=="\\" goto :rete
title Reperibili Live - togli lo sfondo
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@((Join-Path $env:LOCALAPPDATA 'ReperibiliLive'),(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'ReperibiliLive'),(Join-Path $env:USERPROFILE 'ReperibiliLive')) | ForEach-Object { Join-Path $_ 'ReperibiliLive-Sfondo.txt' } | Where-Object { Test-Path $_ } | Select-Object -First 1; if($c){ $RLMode='disinstalla'; iex (Get-Content -Raw -Encoding UTF8 $c) } else { $s=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'; Remove-Item (Join-Path $s 'ReperibiliLive-Sfondo.cmd'),(Join-Path $s 'ReperibiliLive-Finestra.cmd') -Force -ErrorAction SilentlyContinue; Get-CimInstance Win32_Process -Filter 'Name=''powershell.exe'' OR Name=''msedge.exe''' | Where-Object { $_.ProcessId -ne $PID -and (($_.CommandLine -like '*RLMode=''run''*') -or ($_.CommandLine -like '*RLMode=''finestra''*') -or ($_.CommandLine -like '*ReperibiliLive*edge-finestra*')) } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }"
echo.
echo  Sfondo Reperibili Live disattivato: rimesso lo sfondo di prima.
echo.
pause
exit /b 0
:rete
rem  Lanciato da una cartella di rete: da li' il PC non permette di avviare PowerShell.
rem  Si copia in una cartella del PC e la apre, cosi' basta un doppio clic da li'.
set "LOC=%LOCALAPPDATA%\ReperibiliLive"
if not exist "%LOC%" mkdir "%LOC%"
copy /Y "%~f0" "%LOC%\%~nx0" >nul
echo.
echo  Questo file si trova in una cartella di rete: da li' il PC non lo lascia partire.
echo  L'ho copiato in una cartella del computer, che si apre adesso:
echo  fai doppio clic su %~nx0 da quella cartella.
echo.
explorer /select,"%LOC%\%~nx0"
pause
exit /b 0
