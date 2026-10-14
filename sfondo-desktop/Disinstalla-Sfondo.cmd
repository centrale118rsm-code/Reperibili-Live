@echo off
title Reperibili Live - togli lo sfondo
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@((Join-Path $env:LOCALAPPDATA 'ReperibiliLive'),(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'ReperibiliLive'),(Join-Path $env:USERPROFILE 'ReperibiliLive')) | ForEach-Object { Join-Path $_ 'ReperibiliLive-Sfondo.txt' } | Where-Object { Test-Path $_ } | Select-Object -First 1; if($c){ $RLMode='disinstalla'; iex (Get-Content -Raw -Encoding UTF8 $c) } else { Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\ReperibiliLive-Sfondo.cmd') -Force -ErrorAction SilentlyContinue }"
echo.
echo  Sfondo Reperibili Live disattivato: rimesso lo sfondo di prima.
echo.
pause
