<#
  InstaRAR Un-License - Hardened WinRAR License Remover
  
  Forked from neuralpain's unlicenserar and hardened the hell out of it.
  Fixed scope bugs, improved error handling, and made it bulletproof.
  
  This thing will safely remove your WinRAR license with proper backups,
  confirmations, and all the security features you'd expect.
  
  USAGE:
    .\ir_unlicense.ps1                    # Normal operation (with backup and confirmation)
    .\ir_unlicense.ps1 -Force             # Skip confirmation prompts
    .\ir_unlicense.ps1 -NoBackup          # Skip backup creation
    .\ir_unlicense.ps1 -NoElevation       # Don't request admin privileges
    .\ir_unlicense.ps1 -Force -NoBackup   # Quick removal without backup
  
Phil @ DopeDealers - 2025
#>

param(
  [switch]$Force,
  [switch]$NoBackup,
  [switch]$NoElevation,
  [switch]$ElevatedRerun
)

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region Variables
$loc32    = "${env:ProgramFiles(x86)}\WinRAR"
$loc64    = "$env:ProgramFiles\WinRAR"
$loc_multi = "MULTI"  # Clearer flag for dual installations

$winrar64 = "$loc64\WinRAR.exe"
$winrar32 = "$loc32\WinRAR.exe"

$script:rarreg   = $null
$rarreg64 = "$loc64\rarreg.key"
$rarreg32 = "$loc32\rarreg.key"
#endregion

#region Utility Functions - Because life's too short for boring console output
function Write-Info{ Param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Message) ; Write-Host "INFO: $Message" -ForegroundColor DarkCyan }
function Write-Warn{ Param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Message) ; Write-Host "WARN: $Message" -ForegroundColor Yellow }
function Write-Err{ Param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Message) ; Write-Host "ERROR: $Message" -ForegroundColor Red }

function Format-Text {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0,Mandatory=$false,ValueFromPipeline=$true)][String]$Text,
    [Parameter(Mandatory=$false)][ValidateSet(8,24)][Int]$BitDepth,
    [Parameter(Mandatory=$false)][ValidateCount(1,3)][String[]]$Foreground,
    [Parameter(Mandatory=$false)][ValidateCount(1,3)][String[]]$Background,
    [Parameter(Mandatory=$false)][String[]]$Formatting
  )
  $Esc=[char]27
  $Reset="${Esc}[0m"
  switch($BitDepth) {
    8 {
      if($null -eq $Foreground -or $Foreground -lt 0){$Foreground=0}
      if($null -eq $Background -or $Background -lt 0){$Background=0}
      if($Foreground -gt 255){$Foreground=255}
      if($Background -gt 255){$Background=255}
      $Foreground="${Esc}[38;5;${Foreground}m"
      $Background="${Esc}[48;5;${Background}m"
      break
    }
    24 {
      $_foreground=""
      $_background=""
      foreach($color in $Foreground){
        if($null -eq $color -or $color -lt 0){$color=0}
        if($color -gt 255){$color=255}
        $_foreground+=";${color}"
      }
      foreach($color in $Background){
        if($null -eq $color -or $color -lt 0){$color=0}
        if($color -gt 255){$color=255}
        $_background+=";${color}"
      }
      $Foreground="${Esc}[38;2${_foreground}m"
      $Background="${Esc}[48;2${_background}m"
      break
    }
    default {
      switch($Foreground) {
        'Black'{$Foreground="${Esc}[30m"}'DarkRed'{$Foreground="${Esc}[31m"}'DarkGreen'{$Foreground="${Esc}[32m"}'DarkYellow'{$Foreground="${Esc}[33m"}'DarkBlue'{$Foreground="${Esc}[34m"}'DarkMagenta'{$Foreground="${Esc}[35m"}'DarkCyan'{$Foreground="${Esc}[36m"}'Gray'{$Foreground="${Esc}[37m"}'DarkGray'{$Foreground="${Esc}[90m"}'Red'{$Foreground="${Esc}[91m"}'Green'{$Foreground="${Esc}[92m"}'Yellow'{$Foreground="${Esc}[93m"}'Blue'{$Foreground="${Esc}[94m"}'Magenta'{$Foreground="${Esc}[95m"}'Cyan'{$Foreground="${Esc}[96m"}'White'{$Foreground="${Esc}[97m"}default{$Foreground=""}
      }
      switch($Background) {
        'Black'{$Background="${Esc}[40m"}'DarkRed'{$Background="${Esc}[41m"}'DarkGreen'{$Background="${Esc}[42m"}'DarkYellow'{$Background="${Esc}[43m"}'DarkBlue'{$Background="${Esc}[44m"}'DarkMagenta'{$Background="${Esc}[45m"}'DarkCyan'{$Background="${Esc}[46m"}'Gray'{$Background="${Esc}[47m"}'DarkGray'{$Background="${Esc}[100m"}'Red'{$Background="${Esc}[101m"}'Green'{$Background="${Esc}[102m"}'Yellow'{$Background="${Esc}[103m"}'Blue'{$Background="${Esc}[104m"}'Magenta'{$Background="${Esc}[105m"}'Cyan'{$Background="${Esc}[106m"}'White'{$Background="${Esc}[107m"}default{$Background=""}
      }
      break
    }
  }
  if($Formatting -and $Formatting.Length -gt 0){
    $i = 0
    $Format = "${Esc}["
    foreach($type in $Formatting){
      switch($type){
        'Bold'{$Format+="1"}'Dim'{$Format+="2"}'Underline'{$Format+="4"}'Blink'{$Format+="5"}'Reverse'{$Format+="7"}'Hidden'{$Format+="8"}default{$Format+=""}
      }
      $i++
      if($i -lt ($Formatting.Length)) { $Format += ";" } else { $Format += "m"; break }
    }
  } else { $Format = "" }
  $OutString = "${Foreground}${Background}${Format}${Text}${Reset}"
  Write-Output $OutString
}

# Toast notifications with proper error handling for unsupported systems
function New-Toast {
  [CmdletBinding()]
  Param(
    [String]$AppId = "InstaRAR",
    [String]$Url,
    [String]$ToastTitle,
    [String]$ToastText,
    [String]$ToastText2,
    [string]$Attribution,
    [String]$ActionButtonUrl,
    [String]$ActionButtonText = "Open documentation",
    [switch]$KeepAlive,
    [switch]$LongerDuration
  )
  try {
    # Check if toast notifications are supported on this system
    if (-not ("Windows.UI.Notifications.ToastNotificationManager" -as [type])) {
      Write-Warn "Toast notifications are not supported on this system."
      return
    }

    [Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime] | Out-Null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText04)
    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text | Where-Object { $_.id -eq "1" }).AppendChild($RawXml.CreateTextNode($ToastTitle)) | Out-Null
    ($RawXml.toast.visual.binding.text | Where-Object { $_.id -eq "2" }).AppendChild($RawXml.CreateTextNode($ToastText)) | Out-Null
    ($RawXml.toast.visual.binding.text | Where-Object { $_.id -eq "3" }).AppendChild($RawXml.CreateTextNode($ToastText2)) | Out-Null
    $XmlDocument = New-Object Windows.Data.Xml.Dom.XmlDocument
    $XmlDocument.LoadXml($RawXml.OuterXml)

    if ($Url) {
      $XmlDocument.DocumentElement.SetAttribute("activationType","protocol")
      $XmlDocument.DocumentElement.SetAttribute("launch",$Url)
    }
    if ($Attribution) {
      $attrElement = $XmlDocument.CreateElement("text")
      $attrElement.SetAttribute("placement","attribution")
      $attrElement.InnerText = $Attribution
      $bindingElement = $XmlDocument.SelectSingleNode('//toast/visual/binding')
      $bindingElement.AppendChild($attrElement) | Out-Null
    }
    if ($ActionButtonUrl) {
      $actionsElement = $XmlDocument.CreateElement("actions")
      $actionElement = $XmlDocument.CreateElement("action")
      $actionElement.SetAttribute("content",$ActionButtonText)
      $actionElement.SetAttribute("activationType","protocol")
      $actionElement.SetAttribute("arguments",$ActionButtonUrl)
      $actionsElement.AppendChild($actionElement) | Out-Null
      $XmlDocument.DocumentElement.AppendChild($actionsElement) | Out-Null
    }

    if ($KeepAlive) { $XmlDocument.DocumentElement.SetAttribute("scenario","incomingCall") }
    elseif ($LongerDuration) { $XmlDocument.DocumentElement.SetAttribute("duration","long") }

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)
    $Toast.Tag   = "InstaRAR"
    $Toast.Group = "InstaRAR"

    if (-not($KeepAlive -or $LongerDuration)) { 
      $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1) 
    }

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
    $Notifier.Show($Toast)
  } catch {
    # Toasts are best-effort — fall back to Write-Host on error
    Write-Host "Toast creation failed: $($_.Exception.Message)"
  }
}

function Write-Title {
  Write-Host
  Write-Host "   ___           _             " -Foreground Cyan
  Write-Host "  |_ _|_ __  ___| |_ __ _      " -Foreground Cyan
  Write-Host "   | || '_ \/ __| __/ _\`|     " -Foreground Cyan
  Write-Host "   | || | | \__ \ || (_| |     " -Foreground Cyan
  Write-Host "  |___|_| |_|___/\__\__,_|     " -Foreground Cyan
  Write-Host
  Write-Host "   ____    _    ____           " -Foreground Yellow
  Write-Host "  |  _ \  / \  |  _ \          " -Foreground Yellow
  Write-Host "  | |_) |/ _ \ | |_) |         " -Foreground Yellow
  Write-Host "  |  _ <| |_| ||  _ <          " -Foreground Yellow
  Write-Host "  |_| \_\\___/ |_| \_\         " -Foreground Yellow
  Write-Host
  Write-Host "        Hardened License Remover" -Foreground White
  Write-Host "             (ir_unlicense.ps1)" -Foreground DarkGray
  Write-Host
}
Write-Title

# Display active parameter information
if ($Force -or $NoBackup -or $NoElevation) {
  Write-Host "Active Parameters:" -ForegroundColor Cyan
  if ($Force) { Write-Host "  • Force: Confirmation prompts will be skipped" -ForegroundColor Yellow }
  if ($NoBackup) { Write-Host "  • NoBackup: License files will be removed without backup" -ForegroundColor Yellow }
  if ($NoElevation) { Write-Host "  • NoElevation: Admin privileges will not be requested" -ForegroundColor Yellow }
  Write-Host
}

function Stop-OcwrOperation{
  Param([string]$ExitType,[string]$Message)
  switch($ExitType){
    Terminate {
      Write-Host "$Message`nOperation terminated normally."
      if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { Read-Host "Debug pause: Press Enter to exit" | Out-Null }
      exit
    }
    Error {
      Write-Host "ERROR: $Message`nOperation terminated with ERROR." -ForegroundColor Red
      if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { Read-Host "Debug pause: Press Enter to exit" | Out-Null }
      exit 1
    }
    Warning {
      Write-Host "WARN: $Message`nOperation terminated with WARNING." -ForegroundColor Yellow
      if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { Read-Host "Debug pause: Press Enter to exit" | Out-Null }
      exit 2
    }
    Complete {
      Write-Host "$Message`nOperation completed successfully." -ForegroundColor Green
      if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { Read-Host "Debug pause: Press Enter to exit" | Out-Null }
      exit 0
    }
    default {
      Write-Host "$Message`nOperation terminated."
      if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { Read-Host "Debug pause: Press Enter to exit" | Out-Null }
      exit
    }
  }
}

function Confirm-QueryResult{
  [CmdletBinding()]
  param(
    [Parameter(Position=0, Mandatory=$true)][string]$Query,
    [switch]$ExpectPositive,
    [switch]$ExpectNegative,
    [Parameter(Mandatory=$true)][scriptblock]$ResultPositive,
    [Parameter(Mandatory=$true)][scriptblock]$ResultNegative
  )

  $q = Read-Host "$Query $(if($ExpectPositive){"(Y/n)"}elseif($ExpectNegative){"(y/N)"})"

  if ($ExpectPositive) {
    if ($q -match '^(n|N)$') {
      & $ResultNegative
    } else {
      & $ResultPositive
    }
  } elseif ($ExpectNegative) {
    # Accept only explicit 'y' or 'Y' as affirmative; everything else is negative
    if ($q.Length -eq 1 -and $q -match '^(Y|y)$') {
      & $ResultPositive
    } else {
      & $ResultNegative
    }
  } else {
    Write-Err "Nothing to expect."
    Stop-OcwrOperation -ExitType Error
  }
}

function Pause-IfDebug {
  Param([string]$Reason)
  if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') {
    if ($Reason) { Write-Host $Reason -ForegroundColor DarkGray }
    Read-Host "Debug pause: Press Enter to continue" | Out-Null
  }
}
#endregion

#region Hardening Helpers
function Test-IsAdministrator {
  try {
    $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = [Security.Principal.WindowsPrincipal]::new($wi)
    return $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

function Ensure-Directory {
  Param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    try { New-Item -ItemType Directory -Force -Path $Path | Out-Null; return $true }
    catch { Write-Warn "Failed to create directory: $Path. $($_.Exception.Message)"; return $false }
  }
  return $true
}

function Set-FileAttributesNormal {
  Param([Parameter(Mandatory=$true)][string]$Path)
  try {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      (Get-Item -LiteralPath $Path).Attributes = [IO.FileAttributes]::Normal
    }
  } catch {}
}

function Backup-LicenseFile {
  Param([Parameter(Mandatory=$true)][string]$Path)
  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    $timestamp = Get-Date -Format yyyyMMddHHmmss
    $backup = "$Path.removed-$timestamp"
    try {
      Copy-Item -LiteralPath $Path -Destination $backup -Force -ErrorAction Stop
      Write-Info "Backed up license file to: $backup"
      return $true
    }
    catch {
      Write-Warn "Backup failed: $($_.Exception.Message)"
      # Fallback to user-writable TEMP directory
      try {
        $fallbackDir = Join-Path $env:TEMP "InstaRAR\removed_licenses"
        if (-not (Test-Path -LiteralPath $fallbackDir -PathType Container)) { New-Item -ItemType Directory -Force -Path $fallbackDir | Out-Null }
        $fileName = [IO.Path]::GetFileName($Path)
        $fallbackBackup = Join-Path $fallbackDir ("${fileName}.removed-$timestamp")
        Copy-Item -LiteralPath $Path -Destination $fallbackBackup -Force -ErrorAction Stop
        Write-Info "Backed up license file to: $fallbackBackup (fallback)"
        return $true
      } catch {
        Write-Warn "Fallback backup failed: $($_.Exception.Message)"
        return $false
      }
    }
  }
  return $false
}

function Verify-LicenseFile {
  Param([Parameter(Mandatory=$true)][string]$Path)
  try {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
      return $content -match '^RAR registration data'
    }
  } catch {}
  return $false
}

function Remove-LicenseDirect {
  Param([Parameter(Mandatory=$true)][string]$Path)
  try {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      Set-FileAttributesNormal $Path
      Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
      return $true
    }
  } catch { Write-Err "Direct removal failed: $($_.Exception.Message)"; return $false }
  return $false
}

function Invoke-RemoveLicenseElevated {
  Param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$false)][bool]$BackupWanted = $true
  )
  $temp = $null
  try {
    $dir = Split-Path -Parent $Path
    $escapedPath = $Path.Replace("'","''")
    $backupFlag  = if ($BackupWanted) { 'True' } else { 'False' }
    $timestamp   = Get-Date -Format yyyyMMddHHmmss
    $temp = Join-Path $env:TEMP ("ir_unlicense_remove_{0}.ps1" -f ([Guid]::NewGuid().ToString("N")))
    $scriptText = @"
try { (Get-Item -LiteralPath '$escapedPath' -ErrorAction SilentlyContinue).Attributes = [IO.FileAttributes]::Normal } catch {}
if ((Test-Path -LiteralPath '$escapedPath' -PathType Leaf) -and [bool]::Parse('$backupFlag')) {
  try { Copy-Item -LiteralPath '$escapedPath' -Destination ('$escapedPath' + '.removed-$timestamp') -Force -ErrorAction Stop } catch {}
}
if (Test-Path -LiteralPath '$escapedPath' -PathType Leaf) {
  Remove-Item -LiteralPath '$escapedPath' -Force -ErrorAction Stop
}
"@
    Set-Content -LiteralPath $temp -Value $scriptText -Encoding ASCII -Force
    try {
      Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$temp`"" -Wait -ErrorAction Stop
    } catch {
      Write-Err "Failed to launch elevated process: $($_.Exception.Message)"
      try { if ($temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } } catch {}
      return $false
    }

    # Verify removal was successful
    $success = -not (Test-Path -LiteralPath $Path -PathType Leaf)
    try { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } catch {}
    return $success
  } catch {
    Write-Err "Elevated removal failed: $($_.Exception.Message)"
    try { if ($temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } } catch {}
    return $false
  }
}

function Ensure-LicenseRemoval {
  Param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$false)][bool]$CreateBackup = $true)
  
  # Attempt backup first if requested
  if ($CreateBackup -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Info "Creating backup of license file..."
    $backupResult = Backup-LicenseFile $Path
    if (-not $backupResult) {
      Write-Warn "Failed to create backup. Consider using -NoBackup if this is intentional."
    }
  }
  
  if (Remove-LicenseDirect $Path) { return $true }
  Write-Info "Direct removal failed. Attempting elevated license removal..."
  return (Invoke-RemoveLicenseElevated $Path $CreateBackup)
}

function Requires-ElevationForPath {
  Param([Parameter(Mandatory=$true)][string]$Path)
  try {
    if (-not $Path) { return $false }
    $pf   = $env:ProgramFiles
    $pf86 = ${env:ProgramFiles(x86)}
    return ($Path.StartsWith($pf, [StringComparison]::OrdinalIgnoreCase) -or `
            ($pf86 -and $Path.StartsWith($pf86, [StringComparison]::OrdinalIgnoreCase)))
  } catch { return $false }
}

function Request-UpfrontElevation {
  Param(
    [Parameter(Mandatory=$false)][string]$Reason,
    [Parameter(Mandatory=$false)][string]$CdnUrl = 'https://cdn.cyci.org/ir_unlicense.ps1'
  )
  if (Test-IsAdministrator) { return }
  if ($Reason) { Pause-IfDebug $Reason }
  try {
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
      Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ElevatedRerun" -Wait -ErrorAction Stop
    } else {
      $debugPrefix = if ($env:IR_UNLICENSE_DEBUG_PAUSE -eq '1') { "$env:IR_UNLICENSE_DEBUG_PAUSE='1'; " } else { "" }
      Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -Command { ${debugPrefix}irm '" + $CdnUrl + "' | iex }") -Wait -ErrorAction Stop
    }
  } catch {
    Write-Err "Failed to relaunch with elevation: $($_.Exception.Message)"
    Stop-OcwrOperation -ExitType Error -Message "User declined elevation or elevation failed."
  }
  Stop-OcwrOperation -ExitType Terminate -Message "Elevation requested. Relaunching..."
}
#endregion

#region Messages
$UnlicenseSuccess = {
  New-Toast -Url "https://github.com/DopeDealers" -ToastTitle "WinRAR unlicensed successfully" -ToastText "Enjoy your 40-day infinite trial period!" -ToastText2 "Thanks for using InstaRAR"
  Stop-OcwrOperation -ExitType Complete -Message "WinRAR license removed successfully."
}

$Error_UnlicenseFailed = {
  New-Toast -ToastTitle "Unable to un-license WinRAR" -ToastText "A WinRAR license was not found on your device."
  Stop-OcwrOperation -ExitType Error -Message "No license found."
}

$Error_WinrarNotInstalled = {
  New-Toast -ToastTitle "WinRAR is not installed" -ToastText "Check your installation and try again."
  Stop-OcwrOperation -ExitType Error -Message "WinRAR is not installed."
}

$Operation_Cancelled = {
  New-Toast -ToastTitle "Operation cancelled" -ToastText "WinRAR license removal was cancelled by user."
  Stop-OcwrOperation -ExitType Terminate -Message "Operation cancelled by user."
}
#endregion

#region Switch Configs
$script:WINRAR_IS_INSTALLED       = $false
$script:WINRAR_INSTALLED_LOCATION = $null

$script:CREATE_BACKUP    = -not $NoBackup
$script:SKIP_CONFIRMATION = $Force
#endregion

#region Location and Defaults
function Get-InstalledWinrarLocations {
  if ((Test-Path $winrar64 -PathType Leaf) -and (Test-Path $winrar32 -PathType Leaf)) {
    $script:WINRAR_INSTALLED_LOCATION = $loc_multi
    $script:WINRAR_IS_INSTALLED = $true
  }
  elseif (Test-Path $winrar64 -PathType Leaf) {
    $script:WINRAR_INSTALLED_LOCATION = $loc64
    $script:WINRAR_IS_INSTALLED = $true
  }
  elseif (Test-Path $winrar32 -PathType Leaf) {
    $script:WINRAR_INSTALLED_LOCATION = $loc32
    $script:WINRAR_IS_INSTALLED = $true
  }
  else {
    $script:WINRAR_INSTALLED_LOCATION = $null
    $script:WINRAR_IS_INSTALLED = $false
  }
}

function Select-WinrarInstallation {
  if ($script:WINRAR_INSTALLED_LOCATION -eq $loc_multi) {
    Write-Warn "Found 32-bit and 64-bit directories for WinRAR. $(Format-Text "Select one." -Foreground Red)"
    do {
      $query = Read-Host "Enter `"1`" for 32-bit and `"2`" for 64-bit"
      # Fixed: Compare strings instead of integers
      if ($query -eq "1") { $script:WINRAR_INSTALLED_LOCATION = $loc32; break }
      elseif ($query -eq "2") { $script:WINRAR_INSTALLED_LOCATION = $loc64; break }
    } while ($true)
  }
  Write-Info "Selected WinRAR installation: $(Format-Text $($script:WINRAR_INSTALLED_LOCATION) -Foreground White -Formatting Underline)"
}
#endregion

#region Hardened Un-licensing - Because security matters
function Invoke-OcwrUnlicensing {
  if ($script:WINRAR_INSTALLED_LOCATION -eq $loc_multi) {
    Select-WinrarInstallation
  }

  # Select license path according to detected installation
  switch ($script:WINRAR_INSTALLED_LOCATION) {
    $loc64   { $script:rarreg = $rarreg64; break }
    $loc32   { $script:rarreg = $rarreg32; break }
    default  { $script:rarreg = $null }
  }

  if (-not $script:rarreg) {
    Stop-OcwrOperation -ExitType Error -Message "Unable to determine WinRAR installation path."
  }

  # Check if license file exists
  if (-not (Test-Path $script:rarreg -PathType Leaf)) {
    &$Error_UnlicenseFailed
    return
  }

  # Verify it's actually a WinRAR license file
  if (-not (Verify-LicenseFile $script:rarreg)) {
    Write-Warn "File exists but doesn't appear to be a valid WinRAR license."
    if (-not $script:SKIP_CONFIRMATION) {
      Confirm-QueryResult -ExpectNegative `
        -Query "Do you want to remove it anyway?" `
        -ResultPositive { 
          Write-Info "Proceeding with removal..."
        } `
        -ResultNegative { &$Operation_Cancelled }
    }
  }

  # Show license information
  Write-Info "Found WinRAR license file: $($script:rarreg)"
  try {
    $fileInfo = Get-Item -LiteralPath $script:rarreg
    Write-Info "License file size: $($fileInfo.Length) bytes"
    Write-Info "Last modified: $($fileInfo.LastWriteTime)"
  } catch {}

  # Confirmation prompt (unless Force is used)
  if (-not $script:SKIP_CONFIRMATION) {
    Write-Host
    Write-Warn "This will $(if($script:CREATE_BACKUP){"backup and "}else{"permanently "})remove your WinRAR license."
    if ($script:CREATE_BACKUP) {
      Write-Info "A backup will be created before removal."
    } else {
      Write-Warn "No backup will be created (NoBackup parameter used)."
    }
    
    Confirm-QueryResult -ExpectNegative `
      -Query "Are you sure you want to proceed?" `
      -ResultPositive { 
        Write-Info "Proceeding with license removal..."
      } `
      -ResultNegative { &$Operation_Cancelled }
  }

  Pause-IfDebug "About to remove license file."

  Write-Info "Removing license from: $($script:rarreg)"
  if (-not (Ensure-LicenseRemoval $script:rarreg $script:CREATE_BACKUP)) {
    Stop-OcwrOperation -ExitType Error -Message "Unable to remove license file."
  } else {
    Write-Info "License removed successfully."
    &$UnlicenseSuccess
  }
}
#endregion

#region Begin Execution
# Check for upfront elevation when needed
if (-not $ElevatedRerun -and -not (Test-IsAdministrator) -and -not $NoElevation) {
  Write-Info "Checking if elevation will be required..."
  
  # Pre-check if we'll likely need elevation for any WinRAR installation
  $willNeedElevation = $false
  if ((Test-Path $winrar64 -PathType Leaf)) {
    $willNeedElevation = (Requires-ElevationForPath $rarreg64)
  }
  if ((Test-Path $winrar32 -PathType Leaf)) {
    $willNeedElevation = $willNeedElevation -or (Requires-ElevationForPath $rarreg32)
  }
  
  if ($willNeedElevation) {
    Write-Info "This operation requires administrator privileges to remove WinRAR license files."
    Request-UpfrontElevation -Reason "Administrator privileges required for WinRAR license removal."
  }
}

Get-InstalledWinrarLocations

if (-not $script:WINRAR_IS_INSTALLED) {
  &$Error_WinrarNotInstalled
}

# Warn about NoElevation if it might prevent script from working
if ($NoElevation -and -not (Test-IsAdministrator)) {
  $willNeedElevation = $false
  if ((Test-Path $winrar64 -PathType Leaf)) {
    $willNeedElevation = (Requires-ElevationForPath $rarreg64)
  }
  if ((Test-Path $winrar32 -PathType Leaf)) {
    $willNeedElevation = $willNeedElevation -or (Requires-ElevationForPath $rarreg32)
  }
  
  if ($willNeedElevation) {
    Write-Warn "NoElevation parameter used, but administrator privileges may be required."
    Write-Warn "License removal may fail if WinRAR directory is write-protected."
  }
}

Invoke-OcwrUnlicensing
#endregion
