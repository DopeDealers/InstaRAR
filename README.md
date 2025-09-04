<div align="center">

![Cyci Logo](images/fdghtdhd.png)

**Proudly forked by Cyci**

</div>

> [!TIP]
> RARLAB® released WinRAR 7.13! Use [`ir_hardened.ps1`](#Usage) to stay up to date. 🚀
>
> <details>
> <summary>View changes</summary>
>
> ```
>                WinRAR - What's new in the latest version
>
>
>  Version 7.13
>
>  1. Another directory traversal vulnerability, differing from that
>     in WinRAR 7.12, has been fixed.
>
>     When extracting a file, previous versions of WinRAR, Windows versions
>     of RAR, UnRAR, portable UnRAR source code and UnRAR.dll can be tricked
>     into using a path, defined in a specially crafted archive,
>     instead of user specified path.
>
>     Unix versions of RAR, UnRAR, portable UnRAR source code
>     and UnRAR library, also as RAR for Android, are not affected.
>
>     We are thankful to Anton Cherepanov, Peter Kosinar, and Peter Strycek
>     from ESET for letting us know about this security issue.
>
>  2. Bugs fixed:
>
>     a) WinRAR 7.12 "Import settings from file" command failed to restore
>        settings, saved by WinRAR versions preceding 7.12;
>
>     b) WinRAR 7.12 set a larger than specified recovery size for compression
>        profiles, created by WinRAR 5.21 and older.
> ```
>
> </details>

> [!IMPORTANT]
>
> <details>
> <summary><strong>WinRAR drops support for 32-bit Windows Operating Systems and Windows Vista</strong></summary><br/>
>
> As stated by WinRAR in the 6th entry in the `WhatsNew.txt` of version `7.10`, 32-bit operating systems are not supported anymore.
>
> ```
>   6. Windows Vista and 32-bit Windows are not supported anymore.
>      WinRAR requires Windows 7 x64 or later.
>
>      Unlike WinRAR, 32-bit self-extracting modules are still provided
>      as a part of 64-bit installation package.
> ```
>
> If you do need to install 32-bit versions of WinRAR, you can [configure ir_hardened.ps1](#Usage) as `ir_hardened_x32_701.ps1` to install the most recent 32-bit version of WinRAR.
> </details>

# InstaRAR

**Complete hardened WinRAR toolkit with enterprise-grade security**

## What it does

**WinRAR Installation & Updates:**
- Automatically detects the latest WinRAR version
- Downloads from official sources with multiple fallbacks and smart retry logic
- Enhanced Authenticode signature verification with publisher validation
- SHA256 hash verification with cross-source validation
- Certificate pinning with dynamic retrieval and caching
- Handles existing installations gracefully with version comparison
- Closes running WinRAR instances before installing (with graceful and force termination)
- True silent installation without UI prompts (requires admin privileges)

**WinRAR Licensing Management:**
- Securely installs WinRAR licenses with automatic backups
- Intelligently handles privilege elevation only when needed
- Safely removes licenses with verification and backup options
- Comprehensive error handling and user feedback
- Multiple operation modes (Force, NoBackup, NoElevation)

**Universal Features:**
- Enterprise-grade security hardening throughout
- Toast notifications with proper error handling
- Debug support for troubleshooting
- Both PowerShell and CMD wrapper support

## Usage

### Install or update WinRAR (hardened installer)

Direct execution (recommended):
```powershell
irm "https://cdn.cyci.org/ir_hardened.ps1" | iex
```

Local execution:
```powershell
.\ir_hardened.ps1
```

For truly silent installation (no UAC prompts), run as administrator:
```powershell
# Right-click PowerShell and "Run as Administrator", then:
.\ir_hardened.ps1
```

Or double‑click wrapper: ir_hardened.cmd

> **Note**: The script will work without admin privileges but Windows UAC will prompt for permission during installation. This is the normal behavior of UAC.

### License your installed WinRAR (hardened licenser)

Direct execution (recommended):
```powershell
irm "https://cdn.cyci.org/ir_license.ps1" | iex
```

Local execution:
```powershell
.\ir_license.ps1                    # Normal operation (with backup and elevation)
.\ir_license.ps1 -NoBackup          # Skip backup creation
.\ir_license.ps1 -NoElevation       # Don't request admin privileges
```

Or double‑click wrapper: ir_license.cmd

### Remove WinRAR license (hardened unlicenser)

Direct execution (recommended):
```powershell
irm "https://cdn.cyci.org/ir_unlicense.ps1" | iex
```

Local execution:
```powershell
.\ir_unlicense.ps1                    # Normal operation (with backup and confirmation)
.\ir_unlicense.ps1 -Force             # Skip confirmation prompts
.\ir_unlicense.ps1 -NoBackup          # Skip backup creation
.\ir_unlicense.ps1 -NoElevation       # Don't request admin privileges
.\ir_unlicense.ps1 -Force -NoBackup   # Quick removal without backup
```

Or double‑click wrapper: ir_unlicense.cmd

## Advanced Usage

### Debug Mode
Enable debug pausing for troubleshooting:
```powershell
# For licensing operations
$env:IR_LICENSE_DEBUG_PAUSE='1'
.\ir_license.ps1

# For unlicensing operations  
$env:IR_UNLICENSE_DEBUG_PAUSE='1'
.\ir_unlicense.ps1
```

### Combining Parameters
```powershell
# Quick license install without backup or elevation requests
.\ir_license.ps1 -NoBackup -NoElevation

# Force remove license without any prompts or backups
.\ir_unlicense.ps1 -Force -NoBackup
```

### CMD Wrapper Usage
```batch
# Install license with backup (default)
ir_license.cmd

# Remove license quickly
ir_unlicense.cmd -force -nobackup
```

## Key Features

### 🛡️ **Security Hardening**
- **Enhanced certificate pinning**: Dynamic SSL certificate retrieval with caching and fallback validation
- **Smart hash verification**: Cross-validates downloads from multiple official sources
- **URL validation**: Whitelist-based URL filtering with path traversal protection
- **Publisher verification**: Enhanced Authenticode signature validation with trusted publisher checks
- **Smart elevation**: Only requests admin when actually needed, with clear user feedback
- **Automatic backups**: License files backed up with timestamps before any changes
- **Fallback protection**: If primary backup fails, falls back to user TEMP directory
- **File verification**: Validates license files are genuine before operations
- **Path safety**: Proper escaping and handling of special characters in paths
- **Security event logging**: Comprehensive logging to Windows Event Log for audit trails

### ⚡ **User Control**
- **Force mode**: Skip confirmation prompts for automated scenarios
- **NoBackup mode**: Disable backups when not wanted
- **NoElevation mode**: Prevent admin privilege requests
- **Debug support**: Pause at key points for troubleshooting

### 🔧 **Reliability**
- **Comprehensive error handling**: Graceful failures with detailed feedback and recovery options
- **Smart download logic**: Prevents multiple simultaneous download attempts with early exit on success
- **Installation verification**: Multi-level verification including file existence and version checking
- **Process management**: Enhanced WinRAR process detection and graceful/force termination
- **Operation verification**: Confirms operations actually succeeded with multiple validation methods
- **Retry mechanisms**: Exponential backoff and intelligent retry logic for network operations
- **Multi-architecture support**: Handles 32-bit, 64-bit, and mixed installations

### 🎯 **Ease of Use**
- **One-click operation**: Works out of the box with sensible defaults
- **Clear feedback**: Always know what's happening with detailed progress info
- **Toast notifications**: Visual feedback with error handling
- **Both PowerShell & CMD**: Use whatever you prefer, (NOTE) ps1's are available through our CDN, CMD scripts must be downloaded and ran locally

## Evolution from oneclickrar/installrar

InstaRAR's `ir_hardened.ps1` is the spiritual successor to the popular `oneclickrar.cmd` and `installrar.cmd` scripts. We've taken the core concept and hardened it for real-world use:

**What we kept:**
- One-click simplicity 
- Automatic latest version detection
- Silent installation

**What we improved:**
- **Enhanced security hardening**: Multi-layer security with certificate pinning, hash verification, and comprehensive audit logging
- **Smart installation logic**: Prevents multiple simultaneous installations and handles edge cases gracefully
- **Advanced process management**: Enhanced WinRAR detection with graceful and force termination options
- **Comprehensive error handling**: Detailed error checking, recovery options, and user feedback with security event logging
- **Enterprise-grade reliability**: Smart retry logic, installation verification, and robust edge case handling
- **True silent operation**: Properly configured silent installation (requires admin privileges for full automation)
- **PowerShell native**: Modern PowerShell implementation with advanced security features

## Security Features

**Installation Security:**
- **Enhanced publisher verification**: Multi-level Authenticode signature validation with certificate chain verification
- **Smart hash verification**: Cross-validates installers against multiple official download sources
- **Certificate pinning**: Dynamic SSL certificate validation with intelligent CA trust verification
- **URL filtering**: Whitelist-based download source validation with path traversal protection
- **Safe execution**: Copies installers to controlled temp directories with integrity checking
- **Process management**: Enhanced process detection with graceful and force termination options
- **Installation verification**: Multi-point validation to ensure successful installation
- **Security event logging**: Comprehensive audit trail in Windows Event Log

**Licensing Security:**
- **Intelligent elevation**: Only requests admin privileges when actually needed
- **Automatic backups**: Creates timestamped backups with fallback locations
- **File verification**: Validates license files before operations
- **Secure elevated operations**: Uses temporary scripts with unique names for elevation
- **Path safety**: Proper escaping and validation of all file paths

**Universal Security:**
- **Comprehensive error handling**: Graceful failure handling with detailed user feedback
- **Input validation**: Parameter validation with proper types and constraints
- **Operation verification**: Confirms operations actually succeeded before reporting success

## Files

- `ir_hardened.ps1` - Hardened installer (successor to installrar/oneclickrar)
- `ir_hardened.cmd` - CMD wrapper that launches the hardened installer
- `ir_license.ps1` - Hardened licenser (successor to licenserar)
- `ir_license.cmd` - CMD wrapper that launches the hardened licenser
- `ir_unlicense.ps1` - Hardened unlicenser (successor to unlicenserar)
- `ir_unlicense.cmd` - CMD wrapper that launches the hardened unlicenser

## Credits

Built upon the foundation of [neuralpain](https://github.com/neuralpain)'s excellent oneclickwinrar project. We're grateful for the original work on installrar.cmd, oneclickrar.cmd, and unlicenserar.ps1 that inspired this toolkit.

This project represents a complete hardened evolution with enterprise-grade security improvements, comprehensive error handling, and advanced user control features while maintaining the simplicity and effectiveness of the original concept.

---

**Author**: DopeDealers  
**Project**: InstaRAR  
**Year**: 2025

