@echo off
REM InstaRAR Interactive Launcher - CMD Wrapper
REM Launches the PowerShell interactive menu for InstaRAR toolkit
REM Phil @ DopeDealers - 2025

setlocal enabledelayedexpansion

REM Check if PowerShell is available
where powershell >nul 2>nul
if !errorlevel! neq 0 (
    echo ERROR: PowerShell is not available or not in PATH.
    echo Please install PowerShell or run the .ps1 file directly.
    pause
    exit /b 1
)

REM Set console title
title InstaRAR Interactive Launcher

REM Launch the PowerShell script
echo Starting InstaRAR Interactive Launcher...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0instarar.ps1"

REM Check if script executed successfully
if !errorlevel! neq 0 (
    echo.
    echo ERROR: The PowerShell script encountered an error.
    echo Error code: !errorlevel!
    echo.
    echo Please check:
    echo - Internet connection
    echo - PowerShell execution policy
    echo - Script file permissions
    echo.
    pause
    exit /b !errorlevel!
)

REM Clean exit
endlocal
