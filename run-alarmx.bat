@echo off
title AlarmX Helper
set ADB=C:\android\Sdk\platform-tools\adb.exe
set FLUTTER=C:\src\flutter\bin\flutter.bat
cd /d %~dp0

rem Run directly:  run-alarmx.bat apk   -> builds the APK, saves it to the Desktop, exits
if /i "%~1"=="apk" (
  set DIRECT=1
  goto apk
)

:menu
cls
echo ===============================
echo         AlarmX - Menu
echo ===============================
echo  1. Run app on PHONE (USB)
echo  2. Build latest APK -^> Desktop (AlarmX.apk)
echo  3. Show connected devices
echo  4. FIX: stuck / phone not showing
echo  5. Clean project (if build errors)
echo  0. Exit
echo.
choice /c 123450 /n /m "Choose a number: "
if errorlevel 6 exit /b
if errorlevel 5 goto clean
if errorlevel 4 goto fix
if errorlevel 3 goto devices
if errorlevel 2 goto apk
if errorlevel 1 goto phone

:phone
cls
echo Make sure: phone plugged in, USB debugging ON, tapped "Allow" on phone.
echo Waiting for the phone... (close this window to cancel)
"%ADB%" wait-for-usb-device
echo Phone found. Building the app (first time can take 3-5 min)...
echo While running: r = refresh, R = restart, q = stop
for /f %%s in ('"%ADB%" -d get-serialno') do set PHONE=%%s
call "%FLUTTER%" run -d %PHONE%
pause
goto menu

:devices
cls
"%ADB%" devices -l
pause
goto menu

:fix
cls
echo Closing stuck Flutter/Dart processes and restarting adb...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM dartvm.exe >nul 2>&1
"%ADB%" kill-server >nul 2>&1
"%ADB%" start-server >nul 2>&1
echo DONE.
echo  - Phone: unplug and plug back in.
echo  - VS Code: Ctrl+Shift+P, then "Reload Window".
pause
goto menu

:apk
cls
set APPNAME=AlarmX

echo Checking free disk space on C: ...
powershell -NoProfile -Command "if ((Get-PSDrive C).Free -lt 3GB) { exit 1 }"
if errorlevel 1 (
  echo.
  echo NOT ENOUGH DISK SPACE on C: - at least 3 GB is needed to build.
  echo Free some space, then try again.
  goto apk_end
)

echo Building the latest %APPNAME% APK (a few minutes)...
call "%FLUTTER%" build apk --release
if errorlevel 1 (
  echo.
  echo Build FAILED. Try the Clean option first, then try again.
  goto apk_end
)

set BUILT=build\app\outputs\flutter-apk\app-release.apk
if not exist "%BUILT%" (
  echo Build finished but %BUILT% was not found.
  goto apk_end
)

rem Find the real Desktop folder (it can be inside OneDrive).
set DESKTOP=
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set DESKTOP=%%D
if "%DESKTOP%"=="" set DESKTOP=%USERPROFILE%\Desktop

rem Remove the old copy so only the newest APK is on the Desktop.
if exist "%DESKTOP%\%APPNAME%.apk" (
  echo Removing the old %APPNAME%.apk from the Desktop...
  del /f /q "%DESKTOP%\%APPNAME%.apk"
  if exist "%DESKTOP%\%APPNAME%.apk" (
    echo Could not remove the old file. Close anything using it, then try again.
    goto apk_end
  )
)

copy /y "%BUILT%" "%DESKTOP%\%APPNAME%.apk" >nul
if errorlevel 1 (
  echo Could not copy the APK to the Desktop.
  goto apk_end
)

echo.
echo DONE! Saved to your Desktop as %APPNAME%.apk
echo Send that file to the phone (Bluetooth / WhatsApp / USB) and open it to install.
if not defined DIRECT explorer /select,"%DESKTOP%\%APPNAME%.apk"

:apk_end
if defined DIRECT exit /b 0
pause
goto menu

:clean
cls
echo Cleaning the project...
call "%FLUTTER%" clean
call "%FLUTTER%" pub get
echo DONE. Now run the app again.
pause
goto menu
