@echo off
setlocal

REM ============================================================
REM ===============  EASY-TO-EDIT SETTINGS  ====================
REM Path to ModuleManager.ConfigCache
set "moduleManagerCache=F:\SteamLibrary\steamapps\common\Kerbal Space Program\GameData\ModuleManager.ConfigCache"

REM Where to drop the finished zip
REM set "downloads=C:\Users\Bobisback\Downloads"
REM Or make it user-agnostic:
set "downloads=%USERPROFILE%\Downloads"
REM ============================================================

REM Validate source file
if not exist "%moduleManagerCache%" (
  echo [ERROR] Not found: "%moduleManagerCache%"
  echo Make sure the path is correct and the cache exists.
  pause
  exit /b 1
)

REM Build zip name from the file name (ModuleManager.ConfigCache.zip)
for %%A in ("%moduleManagerCache%") do set "zipName=%%~nxA.zip"
set "tempZip=%TEMP%\%zipName%"

REM Clean any previous temp copy
if exist "%tempZip%" del /f /q "%tempZip%" >nul 2>&1

REM ---------- Robust PowerShell call with no inner quotes ----------
REM Pass paths via env vars to avoid quote escaping pitfalls
set "SRC=%moduleManagerCache%"
set "DST=%tempZip%"
powershell -NoProfile -Command "$src=$env:SRC; $dst=$env:DST; if (Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}; Compress-Archive -LiteralPath $src -DestinationPath $dst -Force"
if errorlevel 1 (
  echo [ERROR] PowerShell Compress-Archive failed.
  pause
  exit /b 1
)
REM -----------------------------------------------------------------

if not exist "%tempZip%" (
  echo [ERROR] Failed to create zip: "%tempZip%"
  pause
  exit /b 1
)

REM Ensure Downloads exists
if not exist "%downloads%" mkdir "%downloads%" >nul 2>&1

REM Move to Downloads, overwrite if exists
move /Y "%tempZip%" "%downloads%\%zipName%" >nul

if exist "%downloads%\%zipName%" (
  echo [DONE] Created: "%downloads%\%zipName%"
) else (
  echo [ERROR] Could not move the zip to "%downloads%".
)

echo.
pause
