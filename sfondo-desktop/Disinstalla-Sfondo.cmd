@echo off
title Reperibili Live - togli lo sfondo
set "DEST=%LOCALAPPDATA%\ReperibiliLive"
if exist "%DEST%\ReperibiliLive-Sfondo.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\ReperibiliLive-Sfondo.ps1" -Disinstalla
) else (
  del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ReperibiliLive-Sfondo.cmd" 2>nul
)
echo.
echo  Sfondo Reperibili Live disattivato: rimesso lo sfondo di prima.
echo.
pause
