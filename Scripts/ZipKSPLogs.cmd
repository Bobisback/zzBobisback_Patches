@echo off
setlocal EnableExtensions

REM ============================================================
REM ===============  EASY-TO-EDIT SETTINGS  ====================
REM Files to include
set "KSPLog=F:\SteamLibrary\steamapps\common\Kerbal Space Program\KSP.log"
set "moduleManagerLogUrl=F:\SteamLibrary\steamapps\common\Kerbal Space Program\Logs\ModuleManager\ModuleManager.log"
set "moduleManagerCache=F:\SteamLibrary\steamapps\common\Kerbal Space Program\GameData\ModuleManager.ConfigCache"

REM Where to drop the finished zip
REM set "downloads=C:\Users\Bobisback\Downloads"
REM (Optional) Make it user-agnostic:
set "downloads=%USERPROFILE%\Downloads"

REM Output zip file name
set "zipName=KSPlogs.zip"
REM ============================================================

REM Ensure Downloads exists
if not exist "%downloads%" mkdir "%downloads%" >nul 2>&1

REM Prep a clean staging folder in %TEMP%
set "stage=%TEMP%\KSPlogs_stage"
if exist "%stage%" rmdir /s /q "%stage%"
mkdir "%stage%" || (
  echo [ERROR] Could not create staging folder: "%stage%"
  echo.
  pause
  exit /b 1
)

REM Copy any of the three files that exist into staging (warn if missing)
set "found=0"
for %%F in ("%KSPLog%" "%moduleManagerLogUrl%" "%moduleManagerCache%") do (
  if exist "%%~F" (
    echo [COPY] %%~F
    copy /Y "%%~F" "%stage%\" >nul
    set /a found+=1
  ) else (
    echo [WARN] Not found: %%~F
  )
)

if %found%==0 (
  echo [ERROR] None of the target files were found. Nothing to package.
  echo.
  pause
  exit /b 1
)

REM Build the zip in %TEMP% (overwrite if it already exists)
set "tempZip=%TEMP%\%zipName%"
if exist "%tempZip%" del /f /q "%tempZip%" >nul 2>&1

REM Pass paths via env vars to avoid nested quoting pitfalls
set "STAGE=%stage%"
set "DST=%tempZip%"

powershell -NoProfile -Command ^
  "$src=$env:STAGE; $dst=$env:DST; if (Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}; Compress-Archive -Path ($src + '\*') -DestinationPath $dst -Force"

if not exist "%tempZip%" (
  echo [ERROR] Failed to create zip: "%tempZip%"
  echo.
  pause
  exit /b 1
)

REM Move zip to Downloads, overwrite if exists
move /Y "%tempZip%" "%downloads%\%zipName%" >nul

if exist "%downloads%\%zipName%" (
  echo [DONE] Created: "%downloads%\%zipName%"
) else (
  echo [ERROR] Could not move the zip to "%downloads%".
)

REM Optional: clean up staging folder
if exist "%stage%" rmdir /s /q "%stage%"

echo.
pause
