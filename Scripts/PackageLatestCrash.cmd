@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM ===============  EASY-TO-EDIT SETTINGS  ====================
REM Edit these paths as needed:
set "moduleManagerLogUrl=F:\SteamLibrary\steamapps\common\Kerbal Space Program\Logs\ModuleManager\ModuleManager.log"
set "moduleManagerCache=F:\SteamLibrary\steamapps\common\Kerbal Space Program\GameData\ModuleManager.ConfigCache"
set "KSPLog=F:\SteamLibrary\steamapps\common\Kerbal Space Program\KSP.log"
set "downloads=C:\Users\Bobisback\Downloads"
REM Move files into the crash folder? Set to MOVE or COPY
set "FILE_ACTION=COPY"
REM ============================================================

REM Base directory = the folder where this script lives
set "baseDir=%~dp0"

REM Find the most recently created subfolder in baseDir → currentCrash
for /f "usebackq delims=" %%F in (`
  powershell -NoProfile -Command ^
    "Get-ChildItem -LiteralPath '%~dp0' -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1 -ExpandProperty FullName"
`) do set "currentCrash=%%F"

if not defined currentCrash (
  echo [ERROR] No subfolders found in "%baseDir%".
  echo Place this script one level above your crash folders and try again.
  pause
  exit /b 1
)

echo [INFO] Current crash folder detected:
echo        "%currentCrash%"
echo.

REM Make sure the folder exists (it should)
if not exist "%currentCrash%" mkdir "%currentCrash%"

REM Move/Copy the three files into currentCrash (warn if any are missing)
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

REM Build zip name from the crash folder's name (not full path)
for %%A in ("%currentCrash%") do set "zipName=%%~nA.zip"

REM Create zip in %TEMP% using PowerShell's Compress-Archive
set "zipPath=%TEMP%\%zipName%"
powershell -NoProfile -Command ^
  "$p = '%currentCrash%'; $d = '%zipPath%'; if (Test-Path $d) {Remove-Item $d -Force}; Compress-Archive -Path (Join-Path $p '*') -DestinationPath $d -Force"

if not exist "%zipPath%" (
  echo [ERROR] Failed to create zip: "%zipPath%"
  pause
  exit /b 1
)

REM Ensure Downloads exists, then move the zip there
if not exist "%downloads%" mkdir "%downloads%"
move /Y "%zipPath%" "%downloads%\%zipName%" >nul

echo [DONE] Packaged: "%downloads%\%zipName%"
echo.
pause
