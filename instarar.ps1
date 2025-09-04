<#
  InstaRAR - Interactive Toolkit Launcher
  
  One-stop interactive launcher for the complete InstaRAR toolkit.
  Choose from installation, licensing, or unlicensing operations.
  
  Phil @ DopeDealers - 2025
#>

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# CDN Base URL
$CDN_BASE = "https://cdn.cyci.org"

# Script URLs
$SCRIPTS = @{
    "ir_hardened" = "$CDN_BASE/ir_hardened.ps1"
    "ir_license" = "$CDN_BASE/ir_license.ps1"
    "ir_unlicense" = "$CDN_BASE/ir_unlicense.ps1"
}

function Write-Title {
    Write-Host
    Write-Host "   ___           _             " -ForegroundColor Cyan
    Write-Host "  |_ _|_ __  ___| |_ __ _      " -ForegroundColor Cyan
    Write-Host "   | || '_ \/ __| __/ _\`|     " -ForegroundColor Cyan
    Write-Host "   | || | | \__ \ || (_| |     " -ForegroundColor Cyan
    Write-Host "  |___|_| |_|___/\__\__,_|     " -ForegroundColor Cyan
    Write-Host
    Write-Host "   ____    _    ____           " -ForegroundColor Yellow
    Write-Host "  |  _ \  / \  |  _ \          " -ForegroundColor Yellow
    Write-Host "  | |_) |/ _ \ | |_) |         " -ForegroundColor Yellow
    Write-Host "  |  _ <| |_| ||  _ <          " -ForegroundColor Yellow
    Write-Host "  |_| \_\\___/ |_| \_\         " -ForegroundColor Yellow
    Write-Host
    Write-Host "     Interactive Toolkit Launcher" -ForegroundColor White
    Write-Host "          (instarar.ps1)" -ForegroundColor DarkGray
    Write-Host
}

function Show-Menu {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Select an operation:" -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "  [1] " -ForegroundColor Green -NoNewline
    Write-Host "Install/Update WinRAR" -ForegroundColor White
    Write-Host "      └ Downloads and installs the latest WinRAR" -ForegroundColor DarkGray
    Write-Host
    Write-Host "  [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "License WinRAR" -ForegroundColor White
    Write-Host "      └ Installs WinRAR license with backup" -ForegroundColor DarkGray
    Write-Host
    Write-Host "  [3] " -ForegroundColor Red -NoNewline
    Write-Host "Remove WinRAR License" -ForegroundColor White
    Write-Host "      └ Safely removes WinRAR license" -ForegroundColor DarkGray
    Write-Host
    Write-Host "  [Q] " -ForegroundColor Magenta -NoNewline
    Write-Host "Quit" -ForegroundColor White
    Write-Host
    Write-Host "==========================================" -ForegroundColor Cyan
}

function Invoke-RemoteScript {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptName,
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Description
    )
    
    try {
        Write-Host
        Write-Host ">> $Description..." -ForegroundColor Cyan
        Write-Host "   Downloading from: $Url" -ForegroundColor DarkGray
        Write-Host
        
        # Use the standard irm | iex pattern for remote script execution
        Invoke-RestMethod -Uri $Url | Invoke-Expression
        
        Write-Host
        Write-Host "[SUCCESS] Operation completed successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host
        Write-Host "[ERROR] Error executing $ScriptName : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "        URL: $Url" -ForegroundColor DarkGray
        Write-Host
        Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    }
    finally {
        # Optional: Add cleanup or finalization code here if needed.
        # For now, this block is empty to satisfy the Try-Catch-Finally structure.
    }
}

function Wait-ForKeyPress {
    Write-Host
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main execution
Clear-Host
Write-Title

do {
    Show-Menu
    
    $choice = Read-Host "Enter your choice (1-3, Q to quit)"
    
    switch ($choice.ToUpper()) {
        "1" {
            Clear-Host
            Write-Title
            Invoke-RemoteScript -ScriptName "ir_hardened" -Url $SCRIPTS["ir_hardened"] -Description "Installing/Updating WinRAR"
            Wait-ForKeyPress
            Clear-Host
            Write-Title
        }
        
        "2" {
            Clear-Host
            Write-Title
            Invoke-RemoteScript -ScriptName "ir_license" -Url $SCRIPTS["ir_license"] -Description "Installing WinRAR License"
            Wait-ForKeyPress
            Clear-Host
            Write-Title
        }
        
        "3" {
            Clear-Host
            Write-Title
            Invoke-RemoteScript -ScriptName "ir_unlicense" -Url $SCRIPTS["ir_unlicense"] -Description "Removing WinRAR License"
            Wait-ForKeyPress
            Clear-Host
            Write-Title
        }
        
        "Q" {
            Write-Host
            Write-Host "Thanks for using InstaRAR!" -ForegroundColor Green
            Write-Host "Made with <3 by DopeDealers" -ForegroundColor DarkGray
            Write-Host
            break
        }
        
        default {
            Write-Host
            Write-Host "[!] Invalid choice. Please enter 1, 2, 3, or Q." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Clear-Host
            Write-Title
        }
    }
} while ($choice.ToUpper() -ne "Q")
