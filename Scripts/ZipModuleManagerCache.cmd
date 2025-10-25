@echo off
setlocal EnableExtensions

REM ============================================================
REM ==================  EASY-TO-EDIT SETTINGS  =================
REM Root KSP folder (ONLY THING TO EDIT)
set "KSP_ROOT=F:\SteamLibrary\steamapps\common\Kerbal Space Program"
REM ============================================================

REM ---- Derived paths ----
set "MM_CACHE=%KSP_ROOT%\GameData\ModuleManager.ConfigCache"
set "DOWNLOADS=%USERPROFILE%\Downloads"

REM Validate source file
if not exist "%MM_CACHE%" (
  echo [ERROR] Not found: "%MM_CACHE%"
  echo Make sure the path is correct and the cache exists.
  echo.
  pause
  exit /b 1
)

REM Build zip name from the file name (ModuleManager.ConfigCache.zip)
for %%A in ("%MM_CACHE%") do set "ZIP_NAME=%%~nxA.zip"
set "ZIP_TEMP=%TEMP%\%ZIP_NAME%"

REM Clean any previous temp copy
if exist "%ZIP_TEMP%" del /f /q "%ZIP_TEMP%" >nul 2>&1

REM Robust PowerShell call via env vars (no nested quoting)
set "SRC=%MM_CACHE%"
set "DST=%ZIP_TEMP%"
powershell -NoProfile -Command ^
  "$src=$env:SRC; $dst=$env:DST; if (Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}; Compress-Archive -LiteralPath $src -DestinationPath $dst -Force"

if not exist "%ZIP_TEMP%" (
  echo [ERROR] Failed to create zip: "%ZIP_TEMP%"
  echo.
  pause
  exit /b 1
)

REM Ensure Downloads exists and move/overwrite
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >nul 2>&1
move /Y "%ZIP_TEMP%" "%DOWNLOADS%\%ZIP_NAME%" >nul

if exist "%DOWNLOADS%\%ZIP_NAME%" (
  echo [DONE] Created: "%DOWNLOADS%\%ZIP_NAME%"
) else (
  echo [ERROR] Could not move the zip to "%DOWNLOADS%".
)

echo.
pause
