@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM ==================  EASY-TO-EDIT SETTINGS  =================
REM Location of KSP crash folders (script works no matter where it lives)
set "kspCrashFolder=C:\Users\Bobisback\AppData\Local\Temp\Squad\Kerbal Space Program\Crashes"

REM Files to collect
set "moduleManagerLogUrl=F:\SteamLibrary\steamapps\common\Kerbal Space Program\Logs\ModuleManager\ModuleManager.log"
set "moduleManagerCache=F:\SteamLibrary\steamapps\common\Kerbal Space Program\GameData\ModuleManager.ConfigCache"
set "KSPLog=F:\SteamLibrary\steamapps\common\Kerbal Space Program\KSP.log"

REM Where to drop the final zip
REM set "downloads=C:\Users\Bobisback\Downloads"
REM (Optional) user-agnostic:
set "downloads=%USERPROFILE%\Downloads"

REM COPY vs MOVE the three files into the crash folder
set "FILE_ACTION=COPY"
REM Set to MOVE if you want the originals removed.
REM ============================================================

REM Validate crash root exists
if not exist "%kspCrashFolder%\" (
  echo [ERROR] Crash folder root not found: "%kspCrashFolder%"
  echo        Check the path above and try again.
  goto :end
)

REM Find the most recently CREATED crash subfolder -> currentCrash
REM /ad = directories only, /b = bare names, /o-d = newest first, /t:c = sort by creation time
set "currentCrash="
for /f "usebackq delims=" %%d in (`dir "%kspCrashFolder%" /ad /b /o-d /t:c`) do (
  set "currentCrash=%kspCrashFolder%\%%d"
  goto :gotCrash
)
:gotCrash

if not defined currentCrash (
  echo [ERROR] No crash subfolders found under:
  echo        "%kspCrashFolder%"
  goto :end
)

echo [INFO] Current crash folder:
echo        "%currentCrash%"
echo.

REM Ensure target exists (should already)
if not exist "%currentCrash%\" (
  echo [ERROR] Resolved crash folder doesn't exist:
  echo        "%currentCrash%"
  goto :end
)

REM COPY or MOVE the three files into the crash folder
for %%X in ("%moduleManagerLogUrl%" "%moduleManagerCache%" "%KSPLog%") do (
  if exist "%%~X" (
    if /I "%FILE_ACTION%"=="COPY" (
      echo [COPY] %%~X
      copy /Y "%%~X" "%currentCrash%\" >nul
    ) else (
      echo [MOVE] %%~X
      move /Y "%%~X" "%currentCrash%\" >nul
    )
  ) else (
    echo [WARN] Not found: %%~X
  )
)

echo.

REM Build zip name from the crash folder name and create the zip in %TEMP%
for %%A in ("%currentCrash%") do set "zipName=%%~nA.zip"
set "zipPath=%TEMP%\%zipName%"

REM Clean any prior temp zip
if exist "%zipPath%" del /f /q "%zipPath%" >nul 2>&1

REM Zip the WHOLE crash folder (folder itself inside the zip)
powershell -NoProfile -Command ^
  "$p = '%currentCrash%'; $d = '%zipPath%'; if (Test-Path $d) {Remove-Item $d -Force}; Get-ChildItem -LiteralPath $p | Compress-Archive -DestinationPath $d -Force"

if not exist "%zipPath%" (
  echo [ERROR] Failed to create zip: "%zipPath%"
  goto :end
)

REM Ensure Downloads exists, then move the zip there (overwrite if exists)
if not exist "%downloads%" mkdir "%downloads%" >nul 2>&1
move /Y "%zipPath%" "%downloads%\%zipName%" >nul

if exist "%downloads%\%zipName%" (
  echo [DONE] Packaged crash to:
  echo        "%downloads%\%zipName%"
) else (
  echo [ERROR] Could not move the zip to "%downloads%".
)

:end
echo.
pause
