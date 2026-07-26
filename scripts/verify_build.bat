@echo off
REM Run before presentation — confirms the app compiles.
cd /d "%~dp0.."
echo === flutter pub get ===
call flutter pub get
if errorlevel 1 goto fail

echo === flutter analyze ===
call flutter analyze --no-fatal-infos
if errorlevel 1 goto fail

echo === flutter build web (compile check) ===
call flutter build web --no-tree-shake-icons
if errorlevel 1 goto fail

echo.
echo SUCCESS: Project compiles. Deploy rules: firebase deploy --only firestore:rules
exit /b 0

:fail
echo.
echo FAILED: Fix errors above before your defense.
exit /b 1
