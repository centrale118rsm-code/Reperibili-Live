@echo off
title Reperibili Live - sfondo del desktop
setlocal
set "DEST=%LOCALAPPDATA%\ReperibiliLive"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%~dp0ReperibiliLive-Sfondo.ps1" (
  echo Metti questo file nella stessa cartella di ReperibiliLive-Sfondo.ps1 e riprova.
  pause & exit /b 1
)
if not exist "%DEST%" mkdir "%DEST%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\ReperibiliLive-Sfondo.ps1" -Ferma >nul 2>&1
copy /Y "%~dp0ReperibiliLive-Sfondo.ps1" "%DEST%\ReperibiliLive-Sfondo.ps1" >nul
> "%STARTUP%\ReperibiliLive-Sfondo.cmd" echo @start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%DEST%\ReperibiliLive-Sfondo.ps1"
start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%DEST%\ReperibiliLive-Sfondo.ps1"
echo.
echo  Fatto. Entro un minuto lo sfondo del desktop diventa il monitor dei reperibili
echo  e si aggiorna da solo ogni minuto. All'accensione del PC riparte da solo.
echo.
echo  Se non cambia nulla, guarda il registro: %DEST%\registro.txt
echo  Per toglierlo: Disinstalla-Sfondo.cmd
echo.
pause
