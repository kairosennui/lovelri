@echo off
REM Lovelri — one-shot recovery script
REM Cleans broken .git, re-initializes, links to GitHub, commits, pushes.
REM Double-click in File Explorer to run.

cd /d "%~dp0"

echo ==========================================
echo  Lovelri  --^>  Re-init + push
echo ==========================================
echo.

echo [1/7] Removing broken .git folder (if present)...
if exist ".git" (
  REM Clear read-only / hidden / system attributes recursively first
  attrib -R -H -S ".git" /S /D >nul 2>&1
  rmdir /s /q ".git" 2>nul
  if exist ".git" (
    echo   WARNING: .git still exists. OneDrive may be holding a lock.
    echo   Pause OneDrive sync ^(system tray cloud icon -^> gear -^> Pause^) and run me again.
    pause
    exit /b 1
  )
)
echo   OK
echo.

echo [2/7] Initializing fresh repo on branch 'main'...
git init -b main
if errorlevel 1 goto :err
echo.

echo [3/7] Linking to GitHub remote...
git remote add origin https://github.com/kairosennui/lovelri.git
if errorlevel 1 goto :err
echo.

echo [4/7] Fetching existing history from GitHub...
git fetch origin
if errorlevel 1 goto :err
echo.

echo [5/7] Aligning local HEAD with origin/main (files untouched)...
git reset origin/main
if errorlevel 1 goto :err
echo.

echo [6/7] What's about to be committed:
echo ------------------------------------------
git status --short
echo ------------------------------------------
echo.

set "MSG=Add AR virtual try-on page (try-on.html) + dashboard launcher"
set /p USERMSG="Commit message [%MSG%]: "
if not "%USERMSG%"=="" set "MSG=%USERMSG%"

echo.
echo [7/7] Staging, committing, pushing...
git add .
if errorlevel 1 goto :err
git commit -m "%MSG%"
if errorlevel 1 (
  echo   Nothing to commit, or commit failed. Continuing to push anyway...
)
git push -u origin main
if errorlevel 1 goto :err

echo.
echo ==========================================
echo  Done. Live in ~30 seconds at:
echo  https://kairosennui.github.io/lovelri/try-on.html
echo ==========================================
echo.
pause
exit /b 0

:err
echo.
echo ==========================================
echo  Step failed. See error above.
echo  If "could not lock config" -^> .git is still corrupted.
echo    Pause OneDrive, manually delete .git in File Explorer,
echo    then run this script again.
echo  If "authentication failed" -^> sign in to GitHub when prompted.
echo ==========================================
echo.
pause
exit /b 1
