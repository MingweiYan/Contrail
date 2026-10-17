@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
  -File "%~dp0scripts\deploy_web.ps1" -SkipBuild %*
set "contrail_exit_code=%ERRORLEVEL%"

if not "%contrail_exit_code%"=="0" (
  echo.
  echo Contrail failed to start with exit code %contrail_exit_code%.
  if not defined CI pause
)

exit /b %contrail_exit_code%
