<#
  InstaRAR - Hardened WinRAR Installer
  
  Forked from neuralpain's original script and hardened the hell out of it.
  Added proper signature verification, better error handling, and fixed a bunch of edge cases.
  
  This thing will grab the latest WinRAR, verify it's legit, and install it silently.
  No more sketchy downloads or wondering if you got the real deal.
  
  Phil @ DopeDealers - 2025
#>

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region Variables
$winrar_name_pattern = "^winrar-x"
$winrar_file_pattern = "winrar-x\d{2}-\d{3}\w*\.exe"

$loc32        = "${env:ProgramFiles(x86)}\WinRAR"
$loc64        = "$env:ProgramFiles\WinRAR"
$loc96        = "x96"

$winrar64     = "$loc64\WinRAR.exe"
$winrar32     = "$loc32\WinRAR.exe"

$server1_host = "www.rarlab.com"
$server1      = "https://$server1_host/rar"
$server2_host = "www.win-rar.com"
$server2      = @("https://$server2_host/fileadmin/winrar-versions", "https://$server2_host/fileadmin/winrar-versions/winrar")
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
  Write-Host "        Hardened Silent Installer" -Foreground White
  Write-Host "             (ir_hardened.ps1)" -Foreground DarkGray
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

# Added this because installers hate it when the app is already running - learned this the hard way
function Close-WinRAR {
  Write-Host "Checking for running WinRAR instances..." -ForegroundColor Cyan
  $processes = Get-Process -Name "winrar" -ErrorAction SilentlyContinue

  if (-not $processes) {
    Write-Host "No WinRAR instances found." -ForegroundColor DarkGray
    return
  }

  Write-Host "Closing WinRAR processes..." -ForegroundColor Yellow

  try {
    # Try to be nice about it first - give WinRAR a chance to close properly
    $processes | ForEach-Object { $_.CloseMainWindow() | Out-Null }

    $maxWait = 10
    $elapsed = 0
    while ($elapsed -lt $maxWait) {
      Start-Sleep -Seconds 1
      $elapsed++
      $stillRunning = Get-Process -Name "winrar" -ErrorAction SilentlyContinue
      if (-not $stillRunning) {
        Write-Host "WinRAR closed gracefully." -ForegroundColor Green
        return
      }
    }

    # Alright, being nice didn't work - time for the hammer approach
    Write-Host "WinRAR did not close gracefully. Forcing termination..." -ForegroundColor Yellow
    Get-Process -Name "winrar" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
    Write-Host "All WinRAR processes terminated." -ForegroundColor Green

  } catch {
    Stop-OcwrOperation -ExitType Error -Message "Failed to close WinRAR. Please close it manually."
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
    if ($q -match '^(y|Y)$') {
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

#region Messages
$Error_NoInternetConnection = {
  New-Toast -ToastTitle "No internet" -ToastText "Please check your internet connection."
  Stop-OcwrOperation -ExitType Error -Message "Internet connection lost or unavailable."
}

$Error_UnableToConnectToDownload = {
  New-Toast -ToastTitle "Unable to make a connection" -ToastText "Please check your internet or firewall rules."
  Stop-OcwrOperation -ExitType Error -Message "Unable to make a connection."
}
#endregion

#region WinRAR Updates
function Find-AnyNewWinRarVersions {
  Param([Parameter(Mandatory = $true)][string[]]$URLs)

  foreach ($url in $URLs) {
    try {
      $statusCode = $(Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop).StatusCode
      if ($statusCode -eq 200) {
        return $true
      }
    }
    catch [System.Net.WebException] {
      # 404 or similar: ignore
    }
    catch {
      # ignore other errors; this function only probes availability
    }
  }
}

function Get-WinRarUpdates {
  Param([string[]]$kvList)

  $patch = [int]($kvList[0] % 10)
  $minor = [int](($kvList[0] % 100) / 10)
  $major = [int](($kvList[0] % 1000) / 100)

  $newVersions = @()

  Write-Info "Checking for WinRAR updates..."

  for ($j = $minor; $j -le $minor+1; $j++) {
    if ($j -gt $minor) { $patch = 0 }
    for ($k = $patch; $k -lt 10; $k++) {
      $testVersion = $major*100 + $j*10 + $k
      if ((Find-AnyNewWinRarVersions -URLs @("$server1/winrar-x64-$($testVersion).exe","$($server2[0])/winrar-x64-$($testVersion).exe","$($server2[1])/winrar-x64-$($testVersion).exe"))) {
        $newVersions += $testVersion
      }
    }
  }

  if ($null -ne $newVersions) {
    $newVersions = $($newVersions | Sort-Object -Descending)
    $newVersion = $newVersions[0]
    if ($newVersion -gt $kvList[0]) {
      Write-Info "New version found. Updating default version to $(Format-Text $newVersion -Foreground White)"
      return $newVersions
    } else {
      Write-Info "No WinRAR updates found."
      return $null
    }
  }
}

function Get-WinrarLatestVersion {
  $url = "https://www.rarlab.com/rarnew.htm"
  $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

  Write-Info "Checking latest WinRAR version..."

  try {
    $htmlContent = Invoke-WebRequest -Uri $url -UserAgent $userAgent -UseBasicParsing | Select-Object -ExpandProperty Content
    $_matches = [regex]::Matches($htmlContent, '(?i)Version\s+(\d+\.\d+)')

    if (-not $_matches.Count) {
      Write-Err "Unable to find latest version. The page content might have changed or the request was blocked."
      return 0
    }

    $versions = $_matches.Groups[1].Captures | Select-Object -Unique | ForEach-Object {
      try { [version]$_.Value } catch { }
    }

    if ($versions.Count -eq 0) {
      Write-Err "No valid version numbers were found."
      return 0
    }

    $latestVersion = $versions | Sort-Object -Descending | Select-Object -First 1
    $latestVersion = [int](($latestVersion.Major * 100) + $latestVersion.Minor)
    return $latestVersion
  }
  catch {
    Write-Error "An error occurred during the web request: $($_.Exception.Message)"
    return 0
  }
}
#endregion

$KNOWN_VERSIONS = @(713, 712, 711, 710, 701, 700, 624, 623, 622, 621, 620, 611, 610, 602, 601, 600, 591, 590, 580, 571, 570, 561, 560, 550, 540, 531, 530, 521, 520, 511, 510, 501, 500, 420, 411, 410, 401, 400, 393, 390, 380, 371, 370, 360, 350, 340, 330, 320, 310, 300, 290)
$LATEST = $KNOWN_VERSIONS[0]

if (Test-Connection $server1_host -Count 2 -Quiet) {
  $local:lv = (Get-WinrarLatestVersion)

  if ($local:lv -eq 0) {
    $local:update = Get-WinRarUpdates -kvList $KNOWN_VERSIONS

    if ($null -ne $local:update) {
      $KNOWN_VERSIONS += $local:update
      $KNOWN_VERSIONS = $KNOWN_VERSIONS | Sort-Object -Descending
    }

    $LATEST = $KNOWN_VERSIONS[0]
  } else {
    if ($local:lv -eq $LATEST) {
      Write-Info "Default version is the latest version."
    } else { $LATEST = $local:lv }
  }
} else { &$Error_NoInternetConnection }

#region Switch Configs
$script:WINRAR_EXE          = $null
$script:FETCH_WINRAR        = $false
$script:WINRAR_IS_INSTALLED = $false
$script:WINRAR_INSTALLED_LOCATION = $null

$script:DOWNLOAD_WINRAR     = $false
$script:FORCE_REINSTALL     = $false

$script:ARCH     = $null
$script:RARVER   = $null
$script:TAGS     = $null
#endregion

#region Location and Defaults
function Get-InstalledWinrarLocations {
  if ((Test-Path $winrar64 -PathType Leaf) -and (Test-Path $winrar32 -PathType Leaf)) {
    $script:WINRAR_INSTALLED_LOCATION = $loc96
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

function Set-DefaultArchVersion {
  if ($null -eq $script:ARCH) {
    Write-Info "Using default 64-bit architecture"
    $script:ARCH = "x64"
  }
  if ($null -eq $script:RARVER) {
    Write-Info "Using default version $(Format-Text $(Format-VersionNumber $LATEST) -Foreground White -Formatting Underline)"
    $script:RARVER = $LATEST
  }
  if ($null -eq $script:TAGS) {
    Write-Info "WinRAR language set to $(Format-Text "English" -Foreground White -Formatting Underline)"
    $script:TAGS = ""   # default: no language tag; change to e.g. "-en" if you need tags
  }
}
#endregion

#region Installation helpers
function Format-VersionNumber {
  Param($VersionNumber)
  if ($null -eq $VersionNumber) { return $null }
  return "{0:N2}" -f ($VersionNumber / 100)
}

function Format-VersionNumberFromExecutable {
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    $Executable,
    [Switch]$IntToDouble
  )

  $version = if ($IntToDouble) { $Executable }
             elseif ($Executable -match "(?<version>\d{3})") { $matches['version'] }
             else { return $null }
  $version = Format-VersionNumber $version
  return $version
}

function Get-LocalWinrarInstaller {
  $script:FETCH_WINRAR = $true
  $file_pattern = $winrar_file_pattern
  $name_pattern = $winrar_name_pattern

  $files = Get-ChildItem -Path $pwd | Where-Object { $_.Name -match $name_pattern }

  foreach ($file in $files) {
    if ($file.Name -match $file_pattern) { return $file.FullName }
  }
}

function Get-WinrarInstaller {
  Param($HostUri, $HostUriDir)

  $version = Format-VersionNumber $script:RARVER
  if ($script:TAGS) {
    # attempt to parse tags (e.g. language or beta), but default safely
    $beta = $null
    if ($script:TAGS -match '\d+') { $beta = [regex]::matches($script:TAGS, '\d+')[0].Value }
    $lang = if ($beta) { $script:TAGS.Trim($beta).ToUpper() } else { $script:TAGS.ToUpper() }
  }

  Write-Host "Connecting to $HostUri... "
  if (Test-Connection "$HostUri" -Count 2 -Quiet) {
    try { Invoke-WebRequest -Uri $HostUri -ErrorAction Stop | Out-Null }
    catch { &$Error_UnableToConnectToDownload }

    Write-Host "Verifying download... "

    $fileName = "winrar-$($script:ARCH)-$($script:RARVER)$($script:TAGS).exe"
    $download_url = "$HostUriDir/$fileName"

    try {
      $responseCode = $(Invoke-WebRequest -Uri $download_url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).StatusCode
    }
    catch {
      Write-Error -Message "Unable to download." -ErrorId "404" -Category NotSpecified 2>$null
      return
    }

    if ($responseCode -eq 200) {
      $versionDisplay = $version
      Write-Host "Downloading WinRAR $($versionDisplay)$(if($beta){" Beta $beta"}) ($($script:ARCH))$(if($lang){" ($lang)"})... "
      # Build destination path
      $destFile = Join-Path -Path $PWD.Path -ChildPath $fileName
      try {
        Start-BitsTransfer -Source $download_url -Destination $destFile -ErrorAction Stop
      } catch {
        Write-Error "Download failed: $($_.Exception.Message)"
        throw
      }
    }
    else {
      Write-Error -Message "Download unavailable." -ErrorId "404" -Category NotSpecified 2>$null
    }
  } else { &$Error_NoInternetConnection }
}

function Select-CurrentWinrarInstallation {
  if ($script:WINRAR_INSTALLED_LOCATION -eq $loc96) {
    switch ($script:ARCH) {
      'x64' { $script:WINRAR_INSTALLED_LOCATION = $loc64 ; break }
      'x32' { $script:WINRAR_INSTALLED_LOCATION = $loc32 ; break }
      default { Stop-OcwrOperation -ExitType Error -Message "No architecture provided" }
    }
  }
  Write-Info "Installation directory: $(Format-Text $($script:WINRAR_INSTALLED_LOCATION) -Foreground White -Formatting Underline)"
}

function Confirm-CurrentWinrarInstallation {
  $rarExePath = Join-Path -Path $script:WINRAR_INSTALLED_LOCATION -ChildPath "rar.exe"
  if (Test-Path $rarExePath) {
    try {
      $civ = & $rarExePath -iver 2>$null
    } catch {
      $civ = ""
    }
    if ("$civ" -match $(Format-VersionNumber $script:RARVER)) {
      Write-Info "This version of WinRAR is already installed: $(Format-Text $(Format-VersionNumber $script:RARVER) -Foreground White -Formatting Underline)"
      Confirm-QueryResult -ExpectNegative `
        -Query "Continue with installation?" `
        -ResultPositive {
          Write-Info "Confirmed re-installation of WinRAR version $(Format-Text $(Format-VersionNumber $script:RARVER) -Foreground White -Formatting Underline)"
          Close-WinRAR
          $script:FORCE_REINSTALL = $true
        } `
        -ResultNegative { Stop-OcwrOperation }
    }
  }
}

function Invoke-Installer {
  Param(
    [Parameter(Mandatory=$true)][string]$ExecutablePath,
    [Parameter(Mandatory=$true)][string]$VersionString
  )

  Write-Host "Preparing installation for WinRAR $VersionString..."

  # Security hardening: Never trust executables in random places - copy to our controlled temp space
  $SafeDir = Join-Path $env:TEMP "winrar-installer"
  try { New-Item -ItemType Directory -Force -Path $SafeDir | Out-Null } catch {}
  $TargetExe = Join-Path $SafeDir ([IO.Path]::GetFileName($ExecutablePath))
  try {
    Copy-Item -LiteralPath $ExecutablePath -Destination $TargetExe -Force -ErrorAction Stop
  } catch {
    Write-Err "Failed to copy installer to safe directory: $($_.Exception.Message)"
    Stop-OcwrOperation -ExitType Error -Message "Installer copy failed."
  }

  # 2) Authenticode signature check (require Valid and expected publisher)
  try {
    $sig = Get-AuthenticodeSignature -FilePath $TargetExe -ErrorAction Stop
  } catch {
    Write-Err "Failed to check signature: $($_.Exception.Message)"
    Stop-OcwrOperation -ExitType Error -Message "Signature verification failed."
  }

  $expectedPublisherPattern = 'win\.rar GmbH'  # case-insensitive match in subject
  $signerSubject = ""
  if ($sig.SignerCertificate) { $signerSubject = $sig.SignerCertificate.Subject } else { $signerSubject = "" }

  if ($sig.Status -ne 'Valid' -or -not ($signerSubject -match $expectedPublisherPattern) ) {
    Write-Err "Signature check failed or unexpected publisher: $signerSubject (status: $($sig.Status))"
    New-Toast -ToastTitle "Signature verification failed" -ToastText "Installer did not pass publisher verification. Aborting."
    Stop-OcwrOperation -ExitType Error -Message "Blocked execution due to invalid signature or publisher mismatch."
  } else {
    Write-Info "Signature verified. Publisher: $signerSubject"
  }

  # Optional: sanity check filename
  $expectedName = "winrar-$($script:ARCH)-$($script:RARVER)$($script:TAGS).exe"
  if (([IO.Path]::GetFileName($TargetExe)) -ne $expectedName) {
    Write-Warn "Installer name '$([IO.Path]::GetFileName($TargetExe))' does not match expected name '$expectedName'."
    # You may choose to abort here; currently we warn only.
  }

  # 3) Run installer silently
  Write-Host "Installing WinRAR $VersionString... "
  try {
    Start-Process -FilePath $TargetExe -ArgumentList "/s" -Wait -ErrorAction Stop
  }
  catch {
    New-Toast -ToastTitle "Installation error" -ToastText "The script has run into a problem during installation. Please restart the script."
    Stop-OcwrOperation -ExitType Error -Message "An unknown error occurred during installation: $($_.Exception.Message)"
  }
  finally {
    # Remove temp installer if we copied it
    try { Remove-Item -LiteralPath $TargetExe -Force -ErrorAction SilentlyContinue } catch {}
  }
}

function Invoke-OwcrInstallation {
  $script:WINRAR_EXE = (Get-LocalWinrarInstaller)

  # if there are no installers, proceed to download one
  if ($null -eq $script:WINRAR_EXE) {
    $script:DOWNLOAD_WINRAR = $true

    $Error.Clear()
    $local:retrycount = 0

    # Try primary server
    Get-WinrarInstaller -HostUri $server1_host -HostUriDir $server1

    # Try alternate servers if errors occurred or file not present
    foreach ($wdir in $server2) {
      $localFileName = "winrar-$($script:ARCH)-$($script:RARVER)$($script:TAGS).exe"
      $localFilePath = Join-Path -Path $PWD.Path -ChildPath $localFileName

      if (-not (Test-Path $localFilePath)) {
        $Error.Clear()
        $local:retrycount++
        Write-Host -NoNewLine "`nFailed or not found. Retrying... $local:retrycount`n"
        Get-WinrarInstaller -HostUri $server2_host -HostUriDir $wdir
      }
    }

    # After attempts, check for downloaded installer
    $script:WINRAR_EXE = (Get-LocalWinrarInstaller)

    if ($null -eq $script:WINRAR_EXE) {
      New-Toast -ToastTitle "Unable to fetch download" -ToastText "Are you still connected to the internet?" -ToastText2 "Please check your internet connection."
      Stop-OcwrOperation -ExitType Error -Message "Unable to fetch download"
    }
  }
  else {
    Write-Info "Found executable versioned at $(Format-Text (Format-VersionNumberFromExecutable $script:WINRAR_EXE) -Foreground White -Formatting Underline)"
  }

  # Final invocation
  $exeToRun = $script:WINRAR_EXE
  $versionString = (Format-VersionNumberFromExecutable $script:WINRAR_EXE)
  Invoke-Installer -ExecutablePath $exeToRun -VersionString $versionString
}
#endregion

#region Begin Execution
Get-InstalledWinrarLocations
Set-DefaultArchVersion

if ($script:WINRAR_IS_INSTALLED) {
  Select-CurrentWinrarInstallation
  Confirm-CurrentWinrarInstallation
}

# Only run installation if not already installed or if force reinstall is requested
if (-not $script:WINRAR_IS_INSTALLED -or $script:FORCE_REINSTALL) {
  Invoke-OwcrInstallation
}

New-Toast -Url "https://github.com/DopeDealers" -ToastTitle "WinRAR installed successfully" -ToastText2 "Thanks for using InstaRAR"
Stop-OcwrOperation -ExitType Complete
#endregion
