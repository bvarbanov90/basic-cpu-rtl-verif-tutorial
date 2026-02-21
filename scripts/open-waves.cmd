@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%windows\open-waves.cmd" %*
exit /b %ERRORLEVEL%
