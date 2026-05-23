@echo off
REM =============================================================================
REM  Lovelri  -->  Repair broken .git (iCloud / OneDrive corruption recovery)
REM =============================================================================
REM  Symptom: push.bat shows "fatal: bad object HEAD" because the .git packfile
REM  was never materialised from cloud storage, or sync corrupted the object DB.
REM
REM  This script:
REM    1. Renames the broken .git folder to .git-broken-<timestamp> (kept as
REM       backup — delete manually once you've confirmed everything works).
REM    2. Clones a fresh copy of the repo from GitHub into
REM       %USERPROFILE%\git-repos\lovelri-git  (outside cloud-sync folders, so
REM       the object DB stays healthy forever).
REM    3. Drops a tiny gitfile in this folder pointing at the new .git location.
REM       Git treats it as if .git were still here.
REM    4. Leaves all your edited working files (index.html, bookings.html, etc.)
REM       completely untouched. They will appear as the next pending commit.
REM
REM  After this runs once, push.bat works normally forever.
REM  Run by double-clicking in File Explorer.
REM =============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

set REMOTE_URL=https://github.com/kairosennui/lovelri.git
set NEW_GIT_PARENT=%USERPROFILE%\git-repos
set NEW_GIT_DIR=%NEW_GIT_PARENT%\lovelri-git
set TEMP_CLONE=%NEW_GIT_PARENT%\lovelri-clone-tmp

echo.
echo ==========================================
echo  Lovelri  --^>  Repair broken .git
echo ==========================================
echo.
echo  Repo folder:  %CD%
echo  New .git at:  %NEW_GIT_DIR%
echo  Remote:       %REMOTE_URL%
echo.

where git >nul 2>nul || (
  echo ERROR: git is not on PATH. Install Git for Windows: https://git-scm.com/download/win
  pause & exit /b 1
)

REM ── STEP 1: Move broken .git OUTSIDE the working tree ──────────────────────
REM IMPORTANT: keep the backup OUT of the repo folder. If it sits next to
REM index.html, push.bat's `git add .` will stage 90MB of dead pack data
REM and push it up. Park it under %USERPROFILE%\git-repos\ instead.
echo Step 1 of 4: Backing up broken .git outside the repo ...
if exist .git (
  for /f %%a in ('powershell -nologo -noprofile -command "Get-Date -Format yyyyMMdd-HHmmss"') do set TS=%%a
  if not exist "%NEW_GIT_PARENT%" mkdir "%NEW_GIT_PARENT%"
  set BACKUP_DIR=%NEW_GIT_PARENT%\lovelri-git-broken-!TS!
  robocopy .git "!BACKUP_DIR!" /E /MOVE /NFL /NDL /NJH /NJS /NC /NS >nul
  if errorlevel 8 (
    echo   ERROR: could not move .git. It may be open in another program.
    echo   Close VS Code / GitHub Desktop / any git client and re-run.
    pause & exit /b 1
  )
  echo   .git moved to: !BACKUP_DIR!
  echo   ^(safe to delete manually once push works — never committed to repo^)
) else (
  echo   No .git found — skipping backup.
)
echo.

REM ── STEP 2: Fresh clone into local-only folder ──────────────────────────────
echo Step 2 of 4: Cloning fresh repo to %NEW_GIT_DIR% ...
if not exist "%NEW_GIT_PARENT%" mkdir "%NEW_GIT_PARENT%"
if exist "%TEMP_CLONE%" rmdir /s /q "%TEMP_CLONE%"
if exist "%NEW_GIT_DIR%" (
  echo   Removing previous %NEW_GIT_DIR% ...
  rmdir /s /q "%NEW_GIT_DIR%"
)

git clone "%REMOTE_URL%" "%TEMP_CLONE%"
if errorlevel 1 (
  echo   ERROR: clone failed. Check your internet / GitHub access.
  pause & exit /b 1
)

REM Move just the .git subfolder out of the temp clone — we don't need the
REM working-tree files, your iCloud folder already has them (with your edits).
robocopy "%TEMP_CLONE%\.git" "%NEW_GIT_DIR%" /E /MOVE /NFL /NDL /NJH /NJS /NC /NS
if errorlevel 8 (
  echo   ERROR: robocopy failed moving .git into place.
  pause & exit /b 1
)
rmdir /s /q "%TEMP_CLONE%" 2>nul
echo   OK
echo.

REM ── STEP 3: Drop gitfile pointer in iCloud folder ───────────────────────────
echo Step 3 of 4: Writing .git gitfile pointer ...
> .git echo gitdir: %NEW_GIT_DIR%
echo   OK
echo.

REM Disable auto-gc / auto-pack just like push.bat does — defensive.
git config gc.auto 0 >nul 2>&1
git config gc.autoPackLimit 0 >nul 2>&1
git config gc.autoDetach false >nul 2>&1

REM ── STEP 4: Verify + show pending changes ───────────────────────────────────
echo Step 4 of 4: Verifying ...
git status -sb
if errorlevel 1 (
  echo   ERROR: git status failed after repair.
  pause & exit /b 1
)

echo.
echo ==========================================
echo  Repair complete.
echo.
echo  Your edited files (above) will be the next commit.
echo  Now double-click push.bat to commit and push them to GitHub.
echo ==========================================
echo.
pause
exit /b 0
