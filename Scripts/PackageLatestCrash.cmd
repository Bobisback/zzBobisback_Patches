@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM ==================  EASY-TO-EDIT SETTINGS  =================
REM Root KSP folder (ONLY THING TO EDIT)
set "KSP_ROOT=F:\SteamLibrary\steamapps\common\Kerbal Space Program"

REM COPY vs MOVE the three files into the crash folder
set "FILE_ACTION=COPY"   REM change to MOVE if you want originals removed
REM ============================================================

REM ---- Derive all other paths from KSP_ROOT and user profile ----
for %%A in ("%KSP_ROOT%") do set "KSP_NAME=%%~nxA"
set "KSP_LOG=%KSP_ROOT%\KSP.log"
set "MM_LOG=%KSP_ROOT%\Logs\ModuleManager\ModuleManager.log"
set "MM_CACHE=%KSP_ROOT%\GameData\ModuleManager.ConfigCache"
set "DOWNLOADS=%USERPROFILE%\Downloads"
set "KSP_CRASH_ROOT=%LOCALAPPDATA%\Temp\Squad\%KSP_NAME%\Crashes"

REM Validate crash root exists
if not exist "%KSP_CRASH_ROOT%\" (
  echo [ERROR] Crash folder root not found: "%KSP_CRASH_ROOT%"
  echo        Check KSP_ROOT or run the game to generate a crash first.
  goto :end
)

REM Find the most recently CREATED crash subfolder -> CURRENT_CRASH
set "CURRENT_CRASH="
for /f "usebackq delims=" %%d in (`dir "%KSP_CRASH_ROOT%" /ad /b /o-d /t:c`) do (
  set "CURRENT_CRASH=%KSP_CRASH_ROOT%\%%d"
  goto :gotCrash
)
:gotCrash

if not defined CURRENT_CRASH (
  echo [ERROR] No crash subfolders found under: "%KSP_CRASH_ROOT%"
  goto :end
)

echo [INFO] Current crash folder:
echo        "%CURRENT_CRASH%"
echo.

REM Ensure target exists (should already)
if not exist "%CURRENT_CRASH%\" (
  echo [ERROR] Resolved crash folder doesn't exist:
  echo        "%CURRENT_CRASH%"
  goto :end
)

REM COPY or MOVE the three files into the crash folder
for %%X in ("%MM_LOG%" "%MM_CACHE%" "%KSP_LOG%") do (
  if exist "%%~X" (
    if /I "%FILE_ACTION%"=="COPY" (
      echo [COPY] %%~X
      copy /Y "%%~X" "%CURRENT_CRASH%\" >nul
    ) else (
      echo [MOVE] %%~X
      move /Y "%%~X" "%CURRENT_CRASH%\" >nul
    )
  ) else (
    echo [WARN] Not found: %%~X
  )
)

echo.

REM Build zip name from the crash folder name and create it in %TEMP%
for %%A in ("%CURRENT_CRASH%") do set "ZIP_NAME=%%~nA.zip"
set "ZIP_TEMP=%TEMP%\%ZIP_NAME%"

if exist "%ZIP_TEMP%" del /f /q "%ZIP_TEMP%" >nul 2>&1

REM Zip only the CONTENTS (no parent folder at the root of the zip)
set "SRCFOLDER=%CURRENT_CRASH%"
set "DSTZIP=%ZIP_TEMP%"
powershell -NoProfile -Command ^
  "$src=$env:SRCFOLDER; $dst=$env:DSTZIP; if (Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}; Get-ChildItem -LiteralPath $src -Force | Compress-Archive -DestinationPath $dst -Force"

if not exist "%ZIP_TEMP%" (
  echo [ERROR] Failed to create zip: "%ZIP_TEMP%"
  goto :end
)

REM Ensure Downloads exists, then move the zip there (overwrite if exists)
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >nul 2>&1
move /Y "%ZIP_TEMP%" "%DOWNLOADS%\%ZIP_NAME%" >nul

if exist "%DOWNLOADS%\%ZIP_NAME%" (
  echo [DONE] Packaged crash to:
  echo        "%DOWNLOADS%\%ZIP_NAME%"
) else (
  echo [ERROR] Could not move the zip to "%DOWNLOADS%".
)

:end
echo.
pause
