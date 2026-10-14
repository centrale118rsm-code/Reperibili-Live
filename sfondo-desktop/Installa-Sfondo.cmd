@echo off
title Reperibili Live - sfondo del desktop
setlocal
rem  Installatore in un solo file: lo script PowerShell e' qui in fondo e viene copiato in
rem  %LOCALAPPDATA%\ReperibiliLive. Non servono permessi di amministratore.
set "DEST=%LOCALAPPDATA%\ReperibiliLive"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%DEST%" mkdir "%DEST%"
if exist "%DEST%\ReperibiliLive-Sfondo.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\ReperibiliLive-Sfondo.ps1" -Ferma >nul 2>&1
set "RL_SRC=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:RL_SRC,[Text.Encoding]::UTF8); $m=[char]10+':::'+'SCRIPT:::'; $i=$t.LastIndexOf($m); if($i -lt 0){exit 2}; $s=$t.Substring($i+$m.Length).TrimStart([char]13,[char]10); [IO.File]::WriteAllText((Join-Path $env:LOCALAPPDATA 'ReperibiliLive\ReperibiliLive-Sfondo.ps1'),$s,(New-Object Text.UTF8Encoding $true))"
if errorlevel 1 (
  echo.
  echo  Non sono riuscito a preparare lo script. Riprova dopo aver estratto lo zip in una cartella.
  echo.
  pause & exit /b 1
)
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
exit /b 0
:::SCRIPT:::
# ═══════════════════════════════════════════════════════════════════════════
# REPERIBILI LIVE come SFONDO DEL DESKTOP
# Non installa programmi e non serve essere amministratori.
# Ogni minuto Edge, invisibile, "fotografa" la pagina del monitor e l'immagine
# diventa lo sfondo di Windows: le icone del desktop restano sopra.
# Uso normale: lo avvia Installa-Sfondo.cmd (e poi parte da solo all'accensione).
# ═══════════════════════════════════════════════════════════════════════════
param([switch]$Disinstalla, [switch]$Ferma)

# ── Impostazioni ──
# Parametri utili nell'indirizzo: margine=9 (fascia libera a sinistra per le icone, in % della larghezza)
# tema=notte|chiaro  turni=0..6  rubrica=1|0  orologio=1|0  reperibili=1|0  avviso=1|0  minuti=30
$Url        = 'https://centrale118rsm-code.github.io/Reperibili-Live/?sfondo=1&margine=9'
$Intervallo = 60        # secondi fra un aggiornamento e l'altro (60 = ogni minuto, allineato all'orologio)
$AttesaDati = 20000     # millisecondi lasciati alla pagina per caricare turni e reperibili

$ErrorActionPreference = 'Continue'
$dir     = Join-Path $env:LOCALAPPDATA 'ReperibiliLive'
$profilo = Join-Path $dir 'edge-profilo'
$avvio   = Join-Path ([Environment]::GetFolderPath('Startup')) 'ReperibiliLive-Sfondo.cmd'
$log     = Join-Path $dir 'registro.txt'
New-Item -ItemType Directory -Force -Path $dir, $profilo | Out-Null
function Log($m){ try { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m) } catch {} }
if((Test-Path $log) -and (Get-Item $log).Length -gt 1MB){ Remove-Item $log -Force -ErrorAction SilentlyContinue }

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class RLWin {
  [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool SystemParametersInfo(int a, int b, string c, int d);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern int GetSystemMetrics(int i);
}
"@

function Ferma-Altri {
  try {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
      Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*ReperibiliLive-Sfondo.ps1*' -and $_.CommandLine -notlike '*-Ferma*' -and $_.CommandLine -notlike '*-Disinstalla*' } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  } catch {}
}

if($Ferma){ Ferma-Altri; exit }
if($Disinstalla){
  Ferma-Altri
  Remove-Item $avvio -Force -ErrorAction SilentlyContinue
  $orig = Join-Path $dir 'sfondo-originale.txt'
  if(Test-Path $orig){
    $p = (Get-Content $orig -Raw).Trim()
    if($p -and (Test-Path $p)){ [void][RLWin]::SystemParametersInfo(20, 0, $p, 3) }
  }
  Log 'Disinstallato'
  exit
}

# una sola copia alla volta
$mutex = New-Object System.Threading.Mutex($false, 'Local\ReperibiliLiveSfondo')
if(-not $mutex.WaitOne(0)){ exit }

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
          "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if(-not $edge){ Log 'Microsoft Edge non trovato'; exit 1 }

[void][RLWin]::SetProcessDPIAware()   # risoluzione vera dello schermo, immagine nitida

# sfondo attuale, per rimetterlo con Disinstalla-Sfondo.cmd
$orig = Join-Path $dir 'sfondo-originale.txt'
if(-not (Test-Path $orig)){
  try { (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper | Set-Content -Path $orig -Encoding UTF8 } catch {}
}
try {
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'   # riempi
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'
} catch {}

Log "Avvio con $edge"
$n = 0
while($true){
  try {
    $w = [RLWin]::GetSystemMetrics(0); $h = [RLWin]::GetSystemMetrics(1)
    $file = Join-Path $dir ("sfondo-{0}.png" -f ($n % 2))     # due nomi alternati: Windows ricarica sempre l'immagine
    $tmp  = Join-Path $dir 'scatto.png'
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    $sep = if($Url.Contains('?')){ '&' } else { '?' }
    $u = $Url + $sep + 't=' + [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $argv = @('--headless', '--disable-gpu', '--hide-scrollbars', '--mute-audio', '--no-first-run', '--no-default-browser-check',
              "--user-data-dir=`"$profilo`"", "--window-size=$w,$h", '--force-device-scale-factor=1',
              "--virtual-time-budget=$AttesaDati", "--screenshot=`"$tmp`"", "`"$u`"")
    $p = Start-Process -FilePath $edge -ArgumentList $argv -WindowStyle Hidden -PassThru
    if(-not $p.WaitForExit(90000)){ try { $p.Kill() } catch {}; Log 'Edge non ha risposto in tempo' }
    if((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 15000){
      Move-Item $tmp $file -Force
      if([RLWin]::SystemParametersInfo(20, 0, $file, 3)){ $n++ }
      else { Log 'Windows ha rifiutato lo sfondo (forse bloccato dai criteri aziendali)' }
    } else { Log 'Nessuna immagine prodotta (Edge invisibile bloccato o pagina non raggiungibile)' }
  } catch { Log ('Errore: ' + $_.Exception.Message) }

  if($Intervallo % 60 -eq 0){
    # riparte un attimo dopo l'inizio del minuto, così l'ora sullo sfondo è quella giusta
    $now = Get-Date
    $ms = (60 - $now.Second) * 1000 - $now.Millisecond + 300 + ($Intervallo - 60) * 1000
    Start-Sleep -Milliseconds ([Math]::Max(1000, $ms))
  } else { Start-Sleep -Seconds ([Math]::Max(15, $Intervallo)) }
}
