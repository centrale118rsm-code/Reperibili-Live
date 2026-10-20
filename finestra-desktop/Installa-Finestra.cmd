@echo off
title Reperibili Live - finestra fissa
setlocal
set "SELF=%~f0"
if "%SELF:~0,2%"=="\\" goto :rete
rem  Installatore in un solo file: lo script e' qui in fondo. Viene salvato come testo
rem  (niente .ps1) in una cartella permessa. Non servono permessi di amministratore.
rem  Toglie anche lo sfondo Reperibili Live, se c'era, e rimette quello di prima.
set "RL_SRC=%~f0"
echo.
echo  Preparo la finestra Reperibili Live...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:RL_SRC,[Text.Encoding]::UTF8); $m=[char]10+':::'+'SCRIPT:::'; $i=$t.LastIndexOf($m); if($i -lt 0){exit 2}; $RLText=$t.Substring($i+$m.Length).TrimStart([char]13,[char]10); $RLMode='installa'; iex $RLText"
if errorlevel 1 (
  echo.
  echo  Installazione non riuscita: copia qui sopra le righe in rosso e mandamele.
  echo.
  pause & exit /b 1
)
echo.
echo  Fatto. Tra pochi secondi la finestra dei reperibili compare a destra,
echo  senza bordi e ferma. All'accensione del PC riparte da sola.
echo  Lo sfondo del desktop torna quello di prima.
echo.
echo  Se qualcosa non va, guarda il file registro-finestra.txt nella cartella indicata sopra.
echo  Per toglierla: Disinstalla-Finestra.cmd
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
:::SCRIPT:::
# ═══════════════════════════════════════════════════════════════════════════
# REPERIBILI LIVE in una FINESTRA SENZA BORDI fissa sul desktop
# Nessun programma da installare, nessun permesso di amministratore, nessun file .ps1.
# Edge apre il monitor come finestra; questo script toglie bordi e barra del titolo, la tiene
# ferma al suo posto (sopra la barra delle applicazioni) e la riapre se viene chiusa.
# Modalità ($RLMode): installa | finestra | ferma | disinstalla
# ═══════════════════════════════════════════════════════════════════════════
# ── Impostazioni ──
$Url       = 'https://centrale118rsm-code.github.io/Reperibili-Live/?finestra=1'
$Lato      = 'destra'   # destra | sinistra
$Larghezza = 44         # % della larghezza dello schermo (minimo 700 pixel)
$Altezza   = 100        # % dell'altezza disponibile (la barra delle applicazioni resta libera)
$Livello   = 'sotto'    # sotto = dietro alle altre finestre, come un widget del desktop | sopra = sempre in primo piano

$ErrorActionPreference = 'Continue'
if(-not $RLMode){ $RLMode = 'finestra' }
$NomeTesto   = 'ReperibiliLive-Finestra.txt'
$esecuzione  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$avvio       = Join-Path $esecuzione 'ReperibiliLive-Finestra.cmd'
$avvioSfondo = Join-Path $esecuzione 'ReperibiliLive-Sfondo.cmd'
$candidate = @((Join-Path $env:LOCALAPPDATA 'ReperibiliLive'), (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'ReperibiliLive'), (Join-Path $env:USERPROFILE 'ReperibiliLive'))
$dir = $null
foreach($c in $candidate){ if(Test-Path (Join-Path $c $NomeTesto)){ $dir = $c; break } }
if(-not $dir){ $dir = $candidate[0] }
$log = Join-Path $dir 'registro-finestra.txt'
function Log($m){ try { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m) } catch {} }

$wpOk = $false
try {
  Add-Type -ErrorAction Stop -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class RLWin {
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SystemParametersInfo(int a, int b, string c, int d);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll", EntryPoint = "GetWindowLongW")] public static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll", EntryPoint = "SetWindowLongW")] public static extern int SetWindowLong(IntPtr h, int i, int v);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hh, uint f);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
}
"@
  $wpOk = $true
} catch { }

function Ferma($marca){
  try {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
      Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like "*RLMode='$marca'*" } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  } catch {}
}
function Chiudi-Edge {
  try {
    Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like '*ReperibiliLive*edge-finestra*' } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  } catch {}
}
function Imposta-Sfondo($path){
  try { Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -Value $path } catch {}
  if($wpOk){ [void][RLWin]::SystemParametersInfo(20, 0, $path, 3); return }
  for($k = 0; $k -lt 3; $k++){ Start-Process rundll32.exe -ArgumentList 'user32.dll,UpdatePerUserSystemParameters 1, True' -WindowStyle Hidden -Wait }
}
# toglie lo sfondo Reperibili Live (se c'era) e rimette quello di prima
function Togli-Sfondo {
  Ferma 'run'
  Remove-Item $avvioSfondo -Force -ErrorAction SilentlyContinue
  foreach($c in $candidate){
    $o = Join-Path $c 'sfondo-originale.txt'
    if(Test-Path $o){
      $p = (Get-Content $o -Raw).Trim()
      if($p -and (Test-Path $p)){ Imposta-Sfondo $p; Log "Sfondo originale rimesso: $p" }
      Remove-Item (Join-Path $c 'ReperibiliLive-Sfondo.txt') -Force -ErrorAction SilentlyContinue
      break
    }
  }
}

# ── INSTALLA ──
if($RLMode -eq 'installa'){
  Ferma 'finestra'; Chiudi-Edge; Togli-Sfondo
  $scelta = $null
  foreach($c in $candidate){
    try {
      New-Item -ItemType Directory -Force -Path $c -ErrorAction Stop | Out-Null
      Set-Content -Path (Join-Path $c $NomeTesto) -Value $RLText -Encoding UTF8 -ErrorAction Stop
      $scelta = $c; break
    } catch { Write-Host ("  Cartella non permessa: " + $c) }
  }
  if(-not $scelta){ Write-Host ''; Write-Host '  Nessuna cartella permessa per salvare lo script: il PC lo blocca.'; exit 3 }
  $dir = $scelta; $log = Join-Path $dir 'registro-finestra.txt'
  $txt = Join-Path $dir $NomeTesto
  $cmdRun = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"`$RLMode='finestra'; iex (Get-Content -Raw -Encoding UTF8 '$txt')`""
  try { Set-Content -Path $avvio -Value ('@start "" /min powershell ' + $cmdRun) -Encoding ASCII -ErrorAction Stop }
  catch { Write-Host '  Avvio automatico non creato (cartella Esecuzione automatica bloccata): andra'' lanciato a mano.' }
  Start-Process powershell -ArgumentList $cmdRun -WindowStyle Hidden
  Log "Installato in $dir"
  Write-Host ("  Script salvato in: " + $dir)
  if(-not $wpOk){ Write-Host '  Nota: il PC limita PowerShell, la finestra potrebbe avere ancora il bordo.' }
  exit 0
}
if($RLMode -eq 'ferma'){ Ferma 'finestra'; Chiudi-Edge; exit 0 }
if($RLMode -eq 'disinstalla'){
  Ferma 'finestra'; Chiudi-Edge
  Remove-Item $avvio -Force -ErrorAction SilentlyContinue
  Log 'Disinstallato'
  exit 0
}

# ── FINESTRA: apre Edge e tiene la finestra ferma, senza bordi ──
try {
  $altri = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like "*RLMode='finestra'*" }
  if($altri){ exit 0 }
} catch {}
if((Test-Path $log) -and (Get-Item $log).Length -gt 1MB){ Remove-Item $log -Force -ErrorAction SilentlyContinue }
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
          "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if(-not $edge){ Log 'Microsoft Edge non trovato'; exit 1 }
$profilo = Join-Path $dir 'edge-finestra'
New-Item -ItemType Directory -Force -Path $profilo | Out-Null
if($wpOk){ try { [void][RLWin]::SetProcessDPIAware() } catch {} }
try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop } catch {}

function Area {
  # (in PowerShell maiuscole e minuscole sono la stessa variabile: nomi diversi per schermo e finestra)
  $sx = 0; $sy = 0; $sw = 1920; $sh = 1040
  try { $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea; $sx = $wa.Left; $sy = $wa.Top; $sw = $wa.Width; $sh = $wa.Height } catch {}
  $fw = [int]($sw * $Larghezza / 100); if($fw -lt 700){ $fw = 700 }; if($fw -gt $sw){ $fw = $sw }
  $fh = [int]($sh * $Altezza / 100); if($fh -gt $sh){ $fh = $sh }
  $fx = $sx; if($Lato -ne 'sinistra'){ $fx = $sx + $sw - $fw }
  return @($fx, $sy, $fw, $fh)
}
function Avvia-Edge($r){
  $a = "--app=`"$Url`" --user-data-dir=`"$profilo`" --window-position=$($r[0]),$($r[1]) --window-size=$($r[2]),$($r[3]) " +
       "--no-first-run --no-default-browser-check --hide-crash-restore-bubble --disable-features=Translate,msEdgeSidebarV2"
  Start-Process -FilePath $edge -ArgumentList $a | Out-Null
}
function Trova-Finestra {
  try {
    $ps = Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like '*edge-finestra*' -and $_.CommandLine -notlike '*--type=*' }
    foreach($p in $ps){
      $pr = Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
      if($pr -and $pr.MainWindowHandle -ne [IntPtr]::Zero){ return $pr.MainWindowHandle }
    }
  } catch {}
  return [IntPtr]::Zero
}
$TOGLI = 0x00CF0000          # barra del titolo, bordo, menu, riduci/ingrandisci
$dopo  = if($Livello -eq 'sopra'){ [IntPtr](-1) } else { [IntPtr]1 }   # -1 = sempre sopra, 1 = in fondo
function Sistema($h, $r, $forza){
  $st = [RLWin]::GetWindowLong($h, -16); $ex = [RLWin]::GetWindowLong($h, -20)
  $st2 = $st -band (-bnot $TOGLI)
  $ex2 = ($ex -bor 0x80 -bor 0x08000000) -band (-bnot 0x40000)   # niente icona nella barra, non ruba il primo piano
  $f = 0x10                                                      # non attivare
  if($st2 -ne $st -or $ex2 -ne $ex){ [void][RLWin]::SetWindowLong($h, -16, $st2); [void][RLWin]::SetWindowLong($h, -20, $ex2); $f = $f -bor 0x20; $forza = $true }
  if([RLWin]::IsIconic($h) -or -not [RLWin]::IsWindowVisible($h)){ [void][RLWin]::ShowWindow($h, 4); $forza = $true }
  $rc = New-Object RLWin+RECT; [void][RLWin]::GetWindowRect($h, [ref]$rc)
  if($forza -or $rc.L -ne $r[0] -or $rc.T -ne $r[1] -or ($rc.R - $rc.L) -ne $r[2] -or ($rc.B - $rc.T) -ne $r[3]){
    [void][RLWin]::SetWindowPos($h, $dopo, $r[0], $r[1], $r[2], $r[3], ($f -bor 0x40))
  }
}

Log ("Avvio finestra con $edge" + $(if($wpOk){''}else{' (modalità ridotta: senza togliere i bordi)'}))
$h = [IntPtr]::Zero; $lancio = [datetime]::MinValue; $giro = 0
while($true){
  try {
    $r = Area
    if($h -eq [IntPtr]::Zero -or ($wpOk -and -not [RLWin]::IsWindow($h))){
      $h = Trova-Finestra
      if($h -eq [IntPtr]::Zero){
        if(((Get-Date) - $lancio).TotalSeconds -gt 45){ Avvia-Edge $r; $lancio = Get-Date; Log 'Finestra aperta' }
        Start-Sleep -Seconds 2; continue
      }
      if($wpOk){ Start-Sleep -Milliseconds 800; Sistema $h $r $true }
    }
    if($wpOk){ $giro++; Sistema $h $r ($giro % 20 -eq 0) }
    elseif((Trova-Finestra) -eq [IntPtr]::Zero){ $h = [IntPtr]::Zero }   # senza Add-Type: controlla solo che la finestra ci sia
  } catch { Log ('Errore: ' + $_.Exception.Message); $h = [IntPtr]::Zero }
  Start-Sleep -Milliseconds 1500
}
