@echo off
setlocal
set "SELF=%~f0"
if "%SELF:~0,2%"=="\\" goto :rete
title Reperibili Live - togli la finestra
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@((Join-Path $env:LOCALAPPDATA 'ReperibiliLive'),(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'ReperibiliLive'),(Join-Path $env:USERPROFILE 'ReperibiliLive')) | ForEach-Object { Join-Path $_ 'ReperibiliLive-Finestra.txt' } | Where-Object { Test-Path $_ } | Select-Object -First 1; if($c){ $RLMode='disinstalla'; iex (Get-Content -Raw -Encoding UTF8 $c) } else { Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\ReperibiliLive-Finestra.cmd') -Force -ErrorAction SilentlyContinue }"
echo.
echo  Finestra Reperibili Live chiusa e disattivata.
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
