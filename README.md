> [!TIP]
> RARLAB® released WinRAR 7.13! Use [`ir_hardened.ps1`](#installrarcmd) to stay up to date. 🚀
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
> If you do need to install 32-bit versions of WinRAR, you can [configure installrar.cmd](#configuration) as `installrar_x32_701.cmd` to install the most recent 32-bit version of WinRAR.
> </details>

# InstaRAR

**One-click hardened WinRAR installer**

## What it does

- Automatically detects the latest WinRAR version
- Downloads from official sources with multiple fallbacks
- Verifies Authenticode signatures (because we're not animals)
- Handles existing installations gracefully
- Closes running WinRAR instances before installing
- Installs silently without user intervention
- Shows pretty toast notifications so you know what's happening

## Usage

### Direct execution (recommended)
```powershell
irm "https://cdn.cyci.org/ir_hardened.ps1" | iex
```

### Local execution
```powershell
.\ir_hardened.ps1
```

## Evolution from oneclickrar/installrar

InstaRAR's `ir_hardened.ps1` is the spiritual successor to the popular `oneclickrar.cmd` and `installrar.cmd` scripts. We've taken the core concept and hardened it for real-world use:

**What we kept:**
- One-click simplicity 
- Automatic latest version detection
- Silent installation

**What we improved:**
- **Security hardening**: Proper auth handling
- **Process management**: Graceful WinRAR closure before installation  
- **Better error handling**: Comprehensive error checking and user feedback
- **Edge case handling**: Fixed various bugs and race conditions
- **PowerShell native**: No more batch file limitations

## Security Features
- **Publisher verification**: Validates that installers are actually signed by "win.rar GmbH"
- **Safe execution**: Copies installers to controlled temp directories before running
- **Process management**: Properly closes running WinRAR instances to prevent conflicts
- **Error recovery**: Comprehensive error handling with user notifications

## Files

- `ir_hardened.ps1` - The main hardened installer script (evolved from installrar.ps1/cmd)

## Credits

Originally inspired by [neuralpain](https://github.com/neuralpain)'s oneclickwinrar project (oneclickrar.cmd/installrar.cmd). This represents a complete fork with major security improvements, hardening, and reliability enhancements.

---

**Author**: DopeDealers  
**Project**: InstaRAR  
**Year**: 2025

