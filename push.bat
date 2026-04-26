@echo off
REM Lovelri -- push all current changes to GitHub
REM Double-click this file in File Explorer to run it.

REM Move into the folder this .bat lives in (handles spaces in path)
cd /d "%~dp0"

echo.
echo ==========================================
echo  Lovelri  --^>  GitHub push
echo ==========================================
echo.

echo Files that will be committed:
echo ------------------------------------------
git status --short
echo ------------------------------------------
echo.

set /p MSG="Commit message (press Enter for default): "
if "%MSG%"=="" set MSG=Update hub: bookings, leads, configurator with real ring photos, Sheets backend, redesigned Overview

echo.
echo Staging...
git add .
if errorlevel 1 goto :err

echo.
echo Committing...
git commit -m "%MSG%"
if errorlevel 1 (
  echo.
  echo Nothing to commit, or commit failed. Continuing anyway...
)

echo.
echo Pushing to origin...
git push
if errorlevel 1 goto :err

echo.
echo ==========================================
echo  Done. Your repo:
echo  https://github.com/kairosennui/lovelri
echo ==========================================
echo.
pause
exit /b 0

:err
echo.
echo ==========================================
echo  Push failed. Common causes:
echo   - First-time push: run "git config --global user.name" and "user.email"
echo   - Need to authenticate: run "gh auth login" or set up a PAT
echo   - No remote: run "git remote add origin https://github.com/kairosennui/lovelri.git"
echo ==========================================
echo.
pause
exit /b 1
