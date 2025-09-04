@echo off
:: InstaRAR License - Hardened WinRAR License Installer (CMD Wrapper)
:: 
:: This is a hardened wrapper that calls the main PowerShell license script
:: with all the security improvements and bug fixes intact.
:: 
:: DopeDealers - 2025

setlocal EnableDelayedExpansion

:: Check if we're running with administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WARN: Running without administrator privileges.
    echo Some license operations may require elevation.
    echo.
)

:: Check if we have PowerShell available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo This script requires PowerShell to run the hardened license installer.
    echo.
    echo Please run this on Windows 7 or later, or install PowerShell.
    pause
    exit /b 1
)

:: Check if WinRAR is actually installed before proceeding
if not exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    if not exist "%ProgramFiles(x86)%\WinRAR\WinRAR.exe" (
        echo ERROR: WinRAR is not installed on this system.
        echo Please install WinRAR before attempting to license it.
        echo.
        echo You can use ir_hardened.cmd to install WinRAR first.
        pause
        exit /b 1
    )
)

:: Check if ir_license.ps1 exists in the same directory
if not exist "%~dp0ir_license.ps1" (
    echo INFO: Local ir_license.ps1 not found. Downloading from CDN...
    echo.
    
    :: Try to download the license script
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-RestMethod -Uri 'https://cdn.cyci.org/ir_license.ps1' -OutFile '%~dp0ir_license.ps1' -ErrorAction Stop; Write-Host 'Download successful.' -ForegroundColor Green } catch { Write-Host 'Download failed. Please check your internet connection.' -ForegroundColor Red; exit 1 }"
    
    if %ERRORLEVEL% neq 0 (
        echo.
        echo ERROR: Could not download ir_license.ps1
        echo Please check your internet connection or download manually.
        pause
        exit /b 1
    )
)

:: Verify the PowerShell script exists and is readable
if not exist "%~dp0ir_license.ps1" (
    echo ERROR: ir_license.ps1 not found and download failed.
    echo Please ensure the file is in the same directory as this script.
    pause
    exit /b 1
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
echo       Hardened License Installer
echo            (ir_license.cmd)
echo.

:: Check if there are existing WinRAR processes that might interfere
tasklist /FI "IMAGENAME eq WinRAR.exe" 2>nul | find /I /N "WinRAR.exe" >nul
if %ERRORLEVEL% equ 0 (
    echo WARN: WinRAR is currently running.
    echo This may interfere with license installation.
    echo.
    choice /C YN /M "Close WinRAR and continue"
    if !errorlevel! equ 2 (
        echo Operation cancelled by user.
        pause
        exit /b 0
    )
    
    echo INFO: Attempting to close WinRAR processes...
    taskkill /F /IM WinRAR.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Run the PowerShell license script with bypass execution policy
echo INFO: Launching hardened PowerShell license installer...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ir_license.ps1"

:: Capture the exit code from PowerShell
set PS_EXIT_CODE=%ERRORLEVEL%

echo.
if %PS_EXIT_CODE% equ 0 (
    echo INFO: License installation completed successfully.
    echo.
    echo Your WinRAR installation is now licensed and ready to use!
) else if %PS_EXIT_CODE% equ 1 (
    echo ERROR: License installation failed with an error.
) else if %PS_EXIT_CODE% equ 2 (
    echo WARN: License installation completed with warnings.
) else (
    echo ERROR: License installation failed with exit code %PS_EXIT_CODE%.
)

:: Additional verification - check if license file was actually created
set LICENSE_VERIFIED=0
if exist "%ProgramFiles%\WinRAR\rarreg.key" (
    set LICENSE_VERIFIED=1
    echo INFO: License file verified at: %ProgramFiles%\WinRAR\rarreg.key
)
if exist "%ProgramFiles(x86)%\WinRAR\rarreg.key" (
    set LICENSE_VERIFIED=1
    echo INFO: License file verified at: %ProgramFiles(x86)%\WinRAR\rarreg.key
)

if %LICENSE_VERIFIED% equ 0 (
    echo WARN: Could not verify license file creation.
    echo License installation may not have completed successfully.
)

:: Keep window open if run by double-click
echo %cmdcmdline% | find /i "%~0" >nul
if not errorlevel 1 (
    echo.
    echo Press any key to exit...
    pause >nul
)

exit /b %PS_EXIT_CODE%
