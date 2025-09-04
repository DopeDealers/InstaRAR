@echo off
:: InstaRAR Un-License - Hardened WinRAR License Remover (CMD Wrapper)
:: 
:: This is a hardened wrapper that calls the main PowerShell unlicense script
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
    echo This script requires PowerShell to run the hardened license remover.
    echo.
    echo Please run this on Windows 7 or later, or install PowerShell.
    pause
    exit /b 1
)

:: Check if WinRAR is actually installed before proceeding
if not exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    if not exist "%ProgramFiles(x86)%\WinRAR\WinRAR.exe" (
        echo ERROR: WinRAR is not installed on this system.
        echo Please install WinRAR before attempting to unlicense it.
        echo.
        pause
        exit /b 1
    )
)

:: Check if ir_unlicense.ps1 exists in the same directory
if not exist "%~dp0ir_unlicense.ps1" (
    echo INFO: Local ir_unlicense.ps1 not found. Downloading from CDN...
    echo.
    
    :: Try to download the unlicense script
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-RestMethod -Uri 'https://cdn.cyci.org/ir_unlicense.ps1' -OutFile '%~dp0ir_unlicense.ps1' -ErrorAction Stop; Write-Host 'Download successful.' -ForegroundColor Green } catch { Write-Host 'Download failed. Please check your internet connection.' -ForegroundColor Red; exit 1 }"
    
    if %ERRORLEVEL% neq 0 (
        echo.
        echo ERROR: Could not download ir_unlicense.ps1
        echo Please check your internet connection or download manually.
        pause
        exit /b 1
    )
)

:: Verify the PowerShell script exists and is readable
if not exist "%~dp0ir_unlicense.ps1" (
    echo ERROR: ir_unlicense.ps1 not found and download failed.
    echo Please ensure the file is in the same directory as this script.
    pause
    exit /b 1
)

:: Show banner
echo.
echo    ___           _             
echo   ^|_ _^|_ __  ___^| ^|_ __ _      
echo    ^| ^|^| '_ \\/ __^| __/ _`^|     
echo    ^| ^|^| ^| ^| \\__ \\ ^|^| (_^| ^|     
echo   ^|___^|_^| ^|_^|___/\\__\\__,_^|     
echo.
echo    ____    _    ____           
echo   ^|  _ \\  / \\  ^|  _ \\          
echo   ^| ^|_^) ^|/ _ \\ ^| ^|_^) ^|         
echo   ^|  _ ^<^| ^|_^| ^|^|  _ ^<          
echo   ^|_^| \\_\\\\___/ ^|_^| \\_\\         
echo.
echo       Hardened License Remover
echo            (ir_unlicense.cmd)
echo.

:: Check if there are existing WinRAR processes that might interfere
tasklist /FI "IMAGENAME eq WinRAR.exe" 2>nul | find /I /N "WinRAR.exe" >nul
if %ERRORLEVEL% equ 0 (
    echo WARN: WinRAR is currently running.
    echo This may interfere with license removal.
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

:: Check if there's already no license (quick check)
set LICENSE_EXISTS=0
if exist "%ProgramFiles%\WinRAR\rarreg.key" set LICENSE_EXISTS=1
if exist "%ProgramFiles(x86)%\WinRAR\rarreg.key" set LICENSE_EXISTS=1

if %LICENSE_EXISTS% equ 0 (
    echo INFO: No WinRAR license found. Nothing to remove.
    echo.
    pause
    exit /b 0
)

:: Parse command line arguments for parameters
set PS_PARAMS=
if /i "%1"=="-force" set PS_PARAMS=%PS_PARAMS% -Force
if /i "%1"=="-nobackup" set PS_PARAMS=%PS_PARAMS% -NoBackup
if /i "%1"=="-noelevation" set PS_PARAMS=%PS_PARAMS% -NoElevation
if /i "%2"=="-force" set PS_PARAMS=%PS_PARAMS% -Force
if /i "%2"=="-nobackup" set PS_PARAMS=%PS_PARAMS% -NoBackup
if /i "%2"=="-noelevation" set PS_PARAMS=%PS_PARAMS% -NoElevation
if /i "%3"=="-force" set PS_PARAMS=%PS_PARAMS% -Force
if /i "%3"=="-nobackup" set PS_PARAMS=%PS_PARAMS% -NoBackup
if /i "%3"=="-noelevation" set PS_PARAMS=%PS_PARAMS% -NoElevation

:: Run the PowerShell unlicense script with bypass execution policy
echo INFO: Launching hardened PowerShell license remover...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ir_unlicense.ps1" %PS_PARAMS%

:: Capture the exit code from PowerShell
set PS_EXIT_CODE=%ERRORLEVEL%

echo.
if %PS_EXIT_CODE% equ 0 (
    echo INFO: License removal completed successfully.
    echo.
    echo Your WinRAR installation is now unlicensed and back to trial mode!
) else if %PS_EXIT_CODE% equ 1 (
    echo ERROR: License removal failed with an error.
) else if %PS_EXIT_CODE% equ 2 (
    echo WARN: License removal completed with warnings.
) else (
    echo ERROR: License removal failed with exit code %PS_EXIT_CODE%.
)

:: Additional verification - check if license file was actually removed
set LICENSE_REMOVED=1
if exist "%ProgramFiles%\WinRAR\rarreg.key" (
    set LICENSE_REMOVED=0
    echo WARN: License file still exists at: %ProgramFiles%\WinRAR\rarreg.key
)
if exist "%ProgramFiles(x86)%\WinRAR\rarreg.key" (
    set LICENSE_REMOVED=0
    echo WARN: License file still exists at: %ProgramFiles(x86)%\WinRAR\rarreg.key
)

if %LICENSE_REMOVED% equ 1 (
    echo INFO: License removal verified successfully.
) else (
    echo WARN: License removal may not have completed successfully.
)

:: Keep window open if run by double-click
echo %cmdcmdline% | find /i "%~0" >nul
if not errorlevel 1 (
    echo.
    echo Press any key to exit...
    pause >nul
)

exit /b %PS_EXIT_CODE%
