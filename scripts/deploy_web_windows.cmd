@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
  -File "%~dp0deploy_web.ps1" %*
set "contrail_exit_code=%ERRORLEVEL%"

if not "%contrail_exit_code%"=="0" (
  echo.
  echo Contrail deployment failed with exit code %contrail_exit_code%.
  pause
)

exit /b %contrail_exit_code%
