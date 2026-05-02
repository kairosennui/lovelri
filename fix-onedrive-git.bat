@echo off
REM =============================================================================
REM  Lovelri  -->  One-time fix: move .git OUT of OneDrive
REM =============================================================================
REM  OneDrive locks the .git folder during sync, which causes:
REM    - "fatal: not a git repository" errors (.git seen as cloud placeholder)
REM    - "Deletion of directory '.git/objects/XX' failed" prompt loops
REM    - Files-on-Demand placeholders not getting committed
REM
REM  This script moves .git OUT of OneDrive to a local-only folder, then leaves
REM  a tiny "gitfile" in the OneDrive folder pointing at the new location.
REM  Standard git feature — same mechanism git submodules use.
REM
REM  After running this ONCE, push.bat works without any OneDrive interference.
REM
REM  Run by double-clicking in File Explorer.
REM =============================================================================

setlocal
cd /d "%~dp0"

set NEW_GIT_PARENT=%USERPROFILE%\git-repos
set NEW_GIT_DIR=%NEW_GIT_PARENT%\lovelri-git

echo.
echo ==========================================
echo  Moving .git out of OneDrive
echo ==========================================
echo.
echo  OneDrive folder: %CD%
echo  New .git target: %NEW_GIT_DIR%
echo.

REM Step 1 — sanity check repo state
where git >nul 2>nul || (echo ERROR: git is not on PATH. Install Git for Windows first. & pause & exit /b 1)

if not exist .git (
  echo .git folder/file is missing. Run setup-git.bat first to create one,
  echo then re-run this script.
  pause
  exit /b 1
)

REM If .git is ALREADY a file (gitfile), this script has run before — bail
if not exist .git\HEAD (
  echo .git is already a gitfile pointing outside OneDrive. Nothing to do.
  type .git
  pause
  exit /b 0
)

echo Step 1 of 4: Sanity check (no working-tree files are modified by this script)
git diff-index --quiet HEAD -- 2>nul
if errorlevel 1 (
  echo   You have uncommitted changes in working tree. That's fine — only the
  echo   .git folder is being moved. Your edits are untouched and will appear
  echo   in the next push.bat run as normal.
) else (
  echo   Working tree is clean.
)
echo.

echo Step 2 of 4: Creating target directory...
if not exist "%NEW_GIT_PARENT%" mkdir "%NEW_GIT_PARENT%"
if exist "%NEW_GIT_DIR%" (
  echo   Existing folder at %NEW_GIT_DIR% will be removed first.
  rmdir /s /q "%NEW_GIT_DIR%"
)
echo   OK
echo.

echo Step 3 of 4: Moving .git contents to %NEW_GIT_DIR% ...
REM robocopy /MOVE = copy then delete source. /E = include subdirs incl empty.
REM /NFL /NDL /NJH /NJS = quiet output. Exit codes 0-7 mean success.
robocopy .git "%NEW_GIT_DIR%" /E /MOVE /NFL /NDL /NJH /NJS /NC /NS
if errorlevel 8 (
  echo.
  echo robocopy reported errors. .git move may be incomplete. Check both:
  echo   %CD%\.git
  echo   %NEW_GIT_DIR%
  pause
  exit /b 1
)
echo   OK
echo.

echo Step 4 of 4: Creating gitfile pointer in OneDrive folder...
REM A "gitfile" is a regular file containing one line: "gitdir: <path>".
REM Git sees it instead of the .git folder and follows the pointer.
> .git echo gitdir: %NEW_GIT_DIR%
echo   OK
echo.

REM Make sure git still works from this folder
echo Verifying...
git status -s >nul 2>&1
if errorlevel 1 (
  echo   ERROR: git status failed after move. Something went wrong.
  echo   Check %NEW_GIT_DIR% exists and contains HEAD, config, refs/, etc.
  pause
  exit /b 1
)

echo.
echo ==========================================
echo  Success.
echo  .git is now at: %NEW_GIT_DIR%
echo  OneDrive folder has a tiny gitfile pointing there.
echo.
echo  push.bat will now work without OneDrive interference.
echo  No more deletion-prompt loops.
echo ==========================================
echo.
echo Current branch + last commit:
git status -sb
git log -1 --oneline
echo.
pause
