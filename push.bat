@echo off
REM =============================================================================
REM  Lovelri  -->  push all current changes to GitHub
REM  Double-click in File Explorer to run.
REM =============================================================================
REM  This script is defensive: it tolerates OneDrive lock issues by disabling
REM  git's auto-gc/auto-pack on every run. If you've also run fix-onedrive-git.bat
REM  to move .git out of OneDrive, those defenses become unnecessary but harmless.
REM =============================================================================

setlocal
cd /d "%~dp0"

echo.
echo ==========================================
echo  Lovelri  --^>  GitHub push
echo ==========================================
echo.

REM ── PRE-FLIGHT ──────────────────────────────────────────────────────────────
where git >nul 2>nul || (
  echo ERROR: git is not on PATH. Install Git for Windows: https://git-scm.com/download/win
  echo.
  pause & exit /b 1
)

if not exist .git (
  echo ERROR: No .git found in this folder.
  echo Run setup-git.bat first to initialise the repo.
  echo.
  pause & exit /b 1
)

REM Disable auto-gc / auto-pack — OneDrive locks .git/objects/XX folders during
REM sync, causing "Deletion of '.git/objects/XX' failed" prompt loops. These
REM configs are local to this repo, harmless if .git is outside OneDrive.
git config gc.auto 0 >nul 2>&1
git config gc.autoPackLimit 0 >nul 2>&1
git config gc.autoDetach false >nul 2>&1

REM ── SHOW DIFF ───────────────────────────────────────────────────────────────
echo Files that will be committed:
echo ------------------------------------------
git status --short
echo ------------------------------------------
echo.

REM Bail early if there's nothing to commit AND nothing to push
git status --porcelain > "%TEMP%\lovelri_status.txt"
for %%I in ("%TEMP%\lovelri_status.txt") do set DIFF_BYTES=%%~zI
del "%TEMP%\lovelri_status.txt" >nul 2>&1

if "%DIFF_BYTES%"=="0" (
  echo No local changes. Checking for unpushed commits...
  echo.
  git log @{u}..HEAD --oneline 2>nul
  if errorlevel 1 echo   ^(no upstream branch yet^)
  echo.
  set /p DOPUSH="Push existing commits anyway? (y/n): "
  if /i not "%DOPUSH%"=="y" (echo Done. No changes to push. & pause & exit /b 0)
  goto :pushonly
)

REM ── COMMIT ──────────────────────────────────────────────────────────────────
set /p MSG="Commit message (press Enter for default): "
if "%MSG%"=="" set MSG=Update Lovelri try-on, rings, dashboard

REM Pre-build a stdin file with 500 "n" answers. If git ever asks
REM "Deletion of directory '...' failed. Should I try again? (y/n)"
REM during commit/repack/push, it'll auto-read "n" and continue.
REM This makes pushes immune to Windows Defender / antivirus / OneDrive
REM holding momentary file locks on .git/objects/XX folders.
> "%TEMP%\lovelri_auto_n.txt" (for /l %%i in (1,1,500) do @echo n)

echo.
echo Staging...
git add . < "%TEMP%\lovelri_auto_n.txt"
if errorlevel 1 goto :err

echo Committing...
git commit -m "%MSG%" < "%TEMP%\lovelri_auto_n.txt"
if errorlevel 1 (
  echo Nothing new to commit, or commit failed. Will still attempt push.
)

:pushonly
echo.
echo Pushing to origin (this can take ~30s for large changes)...
git push -u origin main < "%TEMP%\lovelri_auto_n.txt"
if errorlevel 1 (
  del "%TEMP%\lovelri_auto_n.txt" 2>nul
  goto :err
)
del "%TEMP%\lovelri_auto_n.txt" 2>nul

REM ── DONE ────────────────────────────────────────────────────────────────────
echo.
echo ==========================================
echo  Done. Live in ~30 seconds at:
echo  https://kairosennui.github.io/lovelri/
echo  https://github.com/kairosennui/lovelri
echo ==========================================
echo.
pause
exit /b 0

:err
echo.
echo ==========================================
echo  Push failed. Most common fixes:
echo.
echo  ^- "could not lock config" / OneDrive lock issues:
echo      Run fix-onedrive-git.bat ONCE to move .git outside OneDrive.
echo.
echo  ^- "fatal: not a git repository":
echo      Run setup-git.bat to re-init.
echo.
echo  ^- Authentication failed:
echo      A browser popup will ask you to sign in to GitHub. Allow it.
echo      Or in cmd: "gh auth login" if you have GitHub CLI installed.
echo ==========================================
echo.
pause
exit /b 1
