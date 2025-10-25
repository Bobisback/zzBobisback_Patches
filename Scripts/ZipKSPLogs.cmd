@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM ==================  EASY-TO-EDIT SETTINGS  =================
REM Root KSP folder (ONLY THING TO EDIT)
set "KSP_ROOT=F:\SteamLibrary\steamapps\common\Kerbal Space Program"

REM Output zip file name
set "ZIP_NAME=KSPlogs.zip"
REM ============================================================

REM ---- Derived paths ----
set "KSP_LOG=%KSP_ROOT%\KSP.log"
set "MM_LOG=%KSP_ROOT%\Logs\ModuleManager\ModuleManager.log"
set "MM_CACHE=%KSP_ROOT%\GameData\ModuleManager.ConfigCache"
set "DOWNLOADS=%USERPROFILE%\Downloads"

REM Ensure Downloads exists
if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%" >nul 2>&1

REM Prep a clean staging folder in %TEMP%
set "STAGE=%TEMP%\KSPlogs_stage"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%" || (
  echo [ERROR] Could not create staging folder: "%STAGE%"
  echo.
  pause
  exit /b 1
)

REM Copy any of the three files that exist into staging (warn if missing)
set "FOUND=0"
for %%F in ("%KSP_LOG%" "%MM_LOG%" "%MM_CACHE%") do (
  if exist "%%~F" (
    echo [COPY] %%~F
    copy /Y "%%~F" "%STAGE%\" >nul
    set /a FOUND+=1
  ) else (
    echo [WARN] Not found: %%~F
  )
)

if %FOUND%==0 (
  echo [ERROR] None of the target files were found. Nothing to package.
  echo.
  pause
  exit /b 1
)

REM Build the zip in %TEMP% (overwrite if it already exists)
set "ZIP_TEMP=%TEMP%\%ZIP_NAME%"
if exist "%ZIP_TEMP%" del /f /q "%ZIP_TEMP%" >nul 2>&1

REM Pass paths via env vars to avoid nested quoting
set "SRC=%STAGE%"
set "DST=%ZIP_TEMP%"

REM Zip the contents of staging (files at the root of the zip)
powershell -NoProfile -Command ^
  "$src=$env:SRC; $dst=$env:DST; if (Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}; Compress-Archive -Path ($src + '\*') -DestinationPath $dst -Force"

if not exist "%ZIP_TEMP%" (
  echo [ERROR] Failed to create zip: "%ZIP_TEMP%"
  echo.
  pause
  exit /b 1
)

REM Move zip to Downloads, overwrite if exists
move /Y "%ZIP_TEMP%" "%DOWNLOADS%\%ZIP_NAME%" >nul

if exist "%DOWNLOADS%\%ZIP_NAME%" (
  echo [DONE] Created: "%DOWNLOADS%\%ZIP_NAME%"
) else (
  echo [ERROR] Could not move the zip to "%DOWNLOADS%".
)

REM Clean up staging folder
if exist "%STAGE%" rmdir /s /q "%STAGE%"

echo.
pause
