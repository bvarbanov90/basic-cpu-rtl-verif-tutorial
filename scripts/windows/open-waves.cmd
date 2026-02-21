@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "PROJECT_ROOT=%%~fI"

if defined OSS_CAD_SUITE_ROOT (
  set "OSS_ROOT=%OSS_CAD_SUITE_ROOT%"
) else (
  set "OSS_ROOT=%USERPROFILE%\tools\oss-cad-suite\oss-cad-suite"
)

set "GTKWAVE_EXE=%OSS_ROOT%\bin\gtkwave.exe"
set "OSS_LIB=%OSS_ROOT%\lib"
set "DEFAULT_WAVE=%PROJECT_ROOT%\sim_build\simple_cpu_tb.vcd"

if not exist "%GTKWAVE_EXE%" (
  echo [ERROR] GTKWave executable not found: "%GTKWAVE_EXE%"
  echo Run: powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\install-tools.ps1"
  exit /b 1
)

if not exist "%OSS_LIB%\libcairo-2.dll" (
  echo [ERROR] Missing GTK dependency: "%OSS_LIB%\libcairo-2.dll"
  exit /b 1
)

if not exist "%OSS_LIB%\gdk-pixbuf-2.0\2.10.0\loaders\libpixbufloader-svg.dll" (
  if exist "%OSS_ROOT%\share\icons\Adwaita\scalable\status\image-missing.svg" if not exist "%OSS_ROOT%\share\icons\Adwaita\scalable\status\image-missing.svg.bak" (
    ren "%OSS_ROOT%\share\icons\Adwaita\scalable\status\image-missing.svg" "image-missing.svg.bak"
  )
  if exist "%OSS_ROOT%\share\icons\Adwaita\symbolic\status\image-missing-symbolic.svg" if not exist "%OSS_ROOT%\share\icons\Adwaita\symbolic\status\image-missing-symbolic.svg.bak" (
    ren "%OSS_ROOT%\share\icons\Adwaita\symbolic\status\image-missing-symbolic.svg" "image-missing-symbolic.svg.bak"
  )
  if not exist "%OSS_ROOT%\share\icons\Adwaita\16x16\status\image-missing.png" if exist "%OSS_ROOT%\share\icons\Adwaita\16x16\status\image-missing-symbolic.symbolic.png" (
    copy /Y "%OSS_ROOT%\share\icons\Adwaita\16x16\status\image-missing-symbolic.symbolic.png" "%OSS_ROOT%\share\icons\Adwaita\16x16\status\image-missing.png" >nul
  )
  if not exist "%OSS_ROOT%\share\icons\Adwaita\32x32\status\image-missing.png" if exist "%OSS_ROOT%\share\icons\Adwaita\32x32\status\image-missing-symbolic.symbolic.png" (
    copy /Y "%OSS_ROOT%\share\icons\Adwaita\32x32\status\image-missing-symbolic.symbolic.png" "%OSS_ROOT%\share\icons\Adwaita\32x32\status\image-missing.png" >nul
  )
)

if "%~1"=="" (
  set "WAVE_FILE=%DEFAULT_WAVE%"
) else (
  set "WAVE_FILE=%~1"
)

if not exist "%WAVE_FILE%" (
  echo [ERROR] Wave file not found: "%WAVE_FILE%"
  echo Run: powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\run.ps1"
  exit /b 1
)

set "PATH=%OSS_ROOT%\bin;%OSS_ROOT%\lib;%PATH%"
start "" "%GTKWAVE_EXE%" "%WAVE_FILE%"
