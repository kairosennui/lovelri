@echo off
REM =============================================================================
REM  Lovelri  -->  One-time cleanup: remove the .git-broken-* backup from
REM  the working tree AND from the GitHub repo.
REM =============================================================================
REM  After repair-git.bat ran, your old corrupted .git was renamed to
REM  .git-broken-<timestamp>/ and then accidentally pushed (push.bat does
REM  `git add .` which staged it). It's ~90MB of pure noise.
REM
REM  This script:
REM    1. Confirms the broken folder exists locally.
REM    2. Stages its removal in git (so the commit deletes it from the repo).
REM    3. Deletes it from disk (locally).
REM    4. Stages the updated .gitignore (which already excludes .git-broken-*).
REM    5. Commits + pushes the cleanup.
REM
REM  Run by double-clicking in File Explorer.
REM =============================================================================

setlocal
cd /d "%~dp0"

echo.
echo ==========================================
echo  Cleaning up .git-broken-* from repo
echo ==========================================
echo.

where git >nul 2>nul || (
  echo ERROR: git not on PATH.
  pause & exit /b 1
)

REM Find all .git-broken-* folders in this directory
set FOUND=
for /d %%D in (.git-broken-*) do (
  set FOUND=%%D
  echo Found: %%D
  echo Removing from git index ^(this records the deletion in the next commit^)...
  git rm -r --cached "%%D" >nul 2>&1
  if errorlevel 1 (
    echo   git rm --cached failed for %%D. Trying anyway.
  )
  echo Deleting from disk...
  rmdir /s /q "%%D"
  if errorlevel 1 (
    echo   ERROR: rmdir failed for %%D. Close any program that may have it open and retry.
    pause & exit /b 1
  )
  echo   OK
)

if "%FOUND%"=="" (
  echo No .git-broken-* folders found. Nothing to clean.
  pause & exit /b 0
)

REM Stage .gitignore in case it was updated to exclude .git-broken-*
git add .gitignore .test-write >nul 2>&1
del .test-write >nul 2>&1

echo.
echo Committing cleanup...
git commit -m "Remove .git-broken backup folder from repo (was 90MB of stale pack data)"
if errorlevel 1 (
  echo   commit failed. Bailing.
  pause & exit /b 1
)

echo.
echo Pushing...
git push origin main
if errorlevel 1 (
  echo   push failed. Bailing.
  pause & exit /b 1
)

echo.
echo ==========================================
echo  Done. Repo cleaned up.
echo.
echo  NOTE: The 90MB blob is still in git HISTORY on GitHub — it just no
echo  longer appears in the latest commit. To purge it from history entirely
echo  would require a force-push rewrite (BFG or git-filter-repo). Not worth
echo  the risk unless you're hitting GitHub's repo size limit. Tell Claude
echo  if you want to go that route.
echo ==========================================
echo.
pause
exit /b 0
