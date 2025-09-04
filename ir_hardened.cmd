@echo off
:: InstaRAR - Hardened WinRAR Installer (CMD Wrapper)
:: 
:: This is a wrapper that calls the main PowerShell script with all the
:: security hardening and features intact.
:: 
:: DopeDealers - 2025

setlocal EnableDelayedExpansion

:: Check if we have PowerShell available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo This script requires PowerShell to run the hardened installer.
    echo.
    echo Please run this on Windows 7 or later, or install PowerShell.
    pause
    exit /b 1
)

:: Check if ir_hardened.ps1 exists in the same directory
if not exist "%~dp0ir_hardened.ps1" (
    echo INFO: Local ir_hardened.ps1 not found. Downloading from CDN...
    echo.
    
    :: Try to download the script
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-RestMethod -Uri 'https://cdn.cyci.org/ir_hardened.ps1' -OutFile '%~dp0ir_hardened.ps1' -ErrorAction Stop; Write-Host 'Download successful.' -ForegroundColor Green } catch { Write-Host 'Download failed. Please check your internet connection.' -ForegroundColor Red; exit 1 }"
    
    if %ERRORLEVEL% neq 0 (
        echo.
        echo ERROR: Could not download ir_hardened.ps1
        echo Please check your internet connection or download manually.
        pause
        exit /b 1
    )
)

:: Show banner
echo.
echo    ___           _             
echo   ^|_ _^|_ __  ___^| ^|_ __ _        
echo    ^| ^|^| '_ \/ __^| __/ _`^|       
echo    ^| ^|^| ^| ^| \__ \ ^|^| (_^| ^|       
echo   ^|___^|_^| ^|_^|___/\__\__,_^|       
echo.
echo    ____    _    ____             
echo   ^|  _ \  / \  ^|  _ \            
echo   ^| ^|_^) ^|/ _ \ ^| ^|_^) ^|           
echo   ^|  _ ^<^| ^|_^| ^|^|  _ ^<            
echo   ^|_^| \_\\___/ ^|_^| \_\           
echo.
echo        Hardened Silent Installer
echo             (ir_hardened.cmd)
echo.

:: Run the PowerShell script with bypass execution policy
echo INFO: Launching hardened PowerShell installer...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ir_hardened.ps1"

:: Capture the exit code from PowerShell
set PS_EXIT_CODE=%ERRORLEVEL%

echo.
if %PS_EXIT_CODE% equ 0 (
    echo INFO: Installation completed successfully.
) else (
    echo ERROR: Installation failed with exit code %PS_EXIT_CODE%.
)

:: Keep window open if run by double-click
echo %cmdcmdline% | find /i "%~0" >nul
if not errorlevel 1 (
    echo.
    echo Press any key to exit...
    pause >nul
)

exit /b %PS_EXIT_CODE%
