<#
  InstaRAR License - Hardened WinRAR License Installer
  
  Forked from neuralpain's licenserar and hardened the hell out of it.
  Fixed scope bugs, improved error handling, and made it more reliable.
  
  This thing will license your WinRAR installation properly and safely.
  No more silent failures or weird edge cases.
  
  Phil @ DopeDealers - 2025
#>

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region Variables
$loc32    = "${env:ProgramFiles(x86)}\WinRAR"
$loc64    = "$env:ProgramFiles\WinRAR"
$loc_multi = "MULTI"  # Clearer flag for dual installations

$winrar64 = "$loc64\WinRAR.exe"
$winrar32 = "$loc32\WinRAR.exe"

$script:rarreg   = $null
$rarkey   = "RAR registration data`r`nEveryone`r`nGeneral Public License`r`nUID=119fdd47b4dbe9a41555`r`n6412212250155514920287d3b1cc8d9e41dfd22b78aaace2ba4386`r`n9152c1ac6639addbb73c60800b745269020dd21becbc46390d7cee`r`ncce48183d6d73d5e42e4605ab530f6edf8629596821ca042db83dd`r`n68035141fb21e5da4dcaf7bf57494e5455608abc8a9916ffd8e23d`r`n0a68ab79088aa7d5d5c2a0add4c9b3c27255740277f6edf8629596`r`n821ca04340a7c91e88b14ba087e0bfb04b57824193d842e660c419`r`nb8af4562cb13609a2ca469bf36fb8da2eda6f5e978bf1205660302"
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
  Write-Host "        Hardened License Installer" -Foreground White
  Write-Host "             (ir_license.ps1)" -Foreground DarkGray
  Write-Host
}
Write-Title

function Stop-OcwrOperation{
  Param([string]$ExitType,[string]$Message)
  switch($ExitType){
    Terminate { Write-Host "$Message`nOperation terminated normally." ; exit }
    Error     { Write-Host "ERROR: $Message`nOperation terminated with ERROR." -ForegroundColor Red ; exit 1 }
    Warning   { Write-Host "WARN: $Message`nOperation terminated with WARNING." -ForegroundColor Yellow ; exit 2 }
    Complete  { Write-Host "$Message`nOperation completed successfully." -ForegroundColor Green ; exit 0 }
    default   { Write-Host "$Message`nOperation terminated." ; exit }
  }
}

# Fixed the spacing bug in the ExpectNegative branch
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

function Backup-ExistingLicense {
  Param([Parameter(Mandatory=$true)][string]$Path)
  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    $backup = "$Path.bak-$(Get-Date -Format yyyyMMddHHmmss)"
    try { Copy-Item -LiteralPath $Path -Destination $backup -Force -ErrorAction Stop; Write-Info "Backed up existing license to: $backup"; return $true }
    catch { Write-Warn "Backup failed: $($_.Exception.Message)"; return $false }
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

function Write-LicenseDirect {
  Param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][string]$Content)
  try {
    $dir = Split-Path -Parent $Path
    Ensure-Directory $dir | Out-Null
    Set-FileAttributesNormal $Path
    [IO.File]::WriteAllText($Path, $Content, [Text.Encoding]::ASCII)
    return (Verify-LicenseFile $Path)
  } catch { Write-Err "Direct write failed: $($_.Exception.Message)"; return $false }
}

function Invoke-WriteLicenseElevated {
  Param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][string]$Content)
  $temp = $null
  try {
    $dir = Split-Path -Parent $Path
    $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Content))
    $escapedPath = $Path.Replace("'","''")
    $escapedDir  = $dir.Replace("'","''")
    $temp = Join-Path $env:TEMP ("ir_license_write_{0}.ps1" -f ([Guid]::NewGuid().ToString("N")))
    $scriptText = @"
if (-not (Test-Path -LiteralPath '$escapedDir' -PathType Container)) { New-Item -ItemType Directory -Force -Path '$escapedDir' | Out-Null }
`$content = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String('$encoded'))
[IO.File]::WriteAllText('$escapedPath', `$content, [Text.Encoding]::ASCII)
"@
    Set-Content -LiteralPath $temp -Value $scriptText -Encoding ASCII -Force
    try {
      Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$temp`"" -Wait -ErrorAction Stop
    } catch {
      Write-Err "Failed to launch elevated process: $($_.Exception.Message)"
      try { if ($temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } } catch {}
      return $false
    }

    # Detect explicit UAC cancel or incomplete elevated write
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
      Write-Err "Elevated write did not complete or was canceled by user."
      try { if ($temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } } catch {}
      return $false
    }

    $ok = Verify-LicenseFile $Path
    try { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } catch {}
    return $ok
  } catch {
    Write-Err "Elevated write failed: $($_.Exception.Message)"
    try { if ($temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } } catch {}
    return $false
  }
}

function Ensure-LicenseWrite {
  Param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][string]$Content)
  if (Write-LicenseDirect $Path $Content) { return $true }
  Write-Info "Direct write failed. Attempting elevated license write..."
  return (Invoke-WriteLicenseElevated $Path $Content)
}
#endregion

#region Messages
$Error_LicenseExists = {
  New-Toast -LongerDuration -ToastTitle "Unable to license WinRAR" -ToastText "Notice: A WinRAR license already exists."
  Stop-OcwrOperation -ExitType Warning -Message "Unable to license WinRAR due to existing license."
}
#endregion

#region Switch Configs
$script:WINRAR_IS_INSTALLED       = $false
$script:WINRAR_INSTALLED_LOCATION = $null

$script:licensee          = $null
$script:license_type      = $null
$script:CUSTOM_LICENSE    = $false
$script:OVERWRITE_LICENSE = $false
$script:BACKUP_LICENSE    = $true
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

#region Hardened Licensing - Because security matters
function Invoke-OcwrLicensing {
  if ($script:WINRAR_INSTALLED_LOCATION -eq $loc_multi) {
    Select-WinrarInstallation
  }

  # Select destination license path according to detected installation
  switch ($script:WINRAR_INSTALLED_LOCATION) {
    $loc64   { $script:rarreg = $rarreg64; break }
    $loc32   { $script:rarreg = $rarreg32; break }
    default  { $script:rarreg = $null }
  }

  if (-not (Test-Path $script:rarreg -PathType Leaf) -or $script:OVERWRITE_LICENSE) {
    $targetDir = Split-Path -Parent $script:rarreg
    if (-not (Ensure-Directory $targetDir)) {
      Write-Warn "Could not ensure target directory exists: $targetDir"
    }

    if ((Test-Path $script:rarreg -PathType Leaf) -and $script:OVERWRITE_LICENSE -and $script:BACKUP_LICENSE) {
      Backup-ExistingLicense $script:rarreg | Out-Null
    }

    Write-Info "Writing license to: $($script:rarreg)"
    if (-not (Ensure-LicenseWrite $script:rarreg $rarkey)) {
      Stop-OcwrOperation -ExitType Error -Message "Unable to write license file."
    } else {
      Write-Info "License written successfully."
    }
  }
  else {
    Write-Warn "A WinRAR license already exists"
    Confirm-QueryResult -ExpectNegative `
      -Query "Do you want to overwrite the current license?" `
      -ResultPositive {
        $script:OVERWRITE_LICENSE = $true
        Invoke-OcwrLicensing
      } `
      -ResultNegative { &$Error_LicenseExists }
  }
}
#endregion

#region Begin Execution
Get-InstalledWinrarLocations

if (-not $script:WINRAR_IS_INSTALLED) {
  New-Toast -ToastTitle "WinRAR is not installed" -ToastText "Install WinRAR before licensing."
  Stop-OcwrOperation -ExitType Error -Message "WinRAR is not installed."
}

Invoke-OcwrLicensing

New-Toast -Url "https://github.com/DopeDealers" -ToastTitle "WinRAR License installed successfully" -ToastText2 "Thanks for using InstaRAR"
Stop-OcwrOperation -ExitType Complete
#endregion
