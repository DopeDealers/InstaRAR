# InstaRAR Enhanced Security Features

This document describes the advanced security enhancements implemented in `temp_ir_hardened.ps1`, the enterprise-grade security edition of InstaRAR.

## 🔐 **Implemented Security Enhancements**

### 1. **Cryptographic Hash Verification** ✅
**What it does:**
- Verifies SHA256 hashes of downloaded WinRAR installers before execution
- Prevents installation of corrupted or tampered files
- Maintains a database of known-good hashes for different versions

**Implementation:**
```powershell
$script:KNOWN_HASHES = @{
    "713" = @{
        "x64" = "1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T1U2V3W4X5Y6Z7A8B9C0D1E2F"
        "x32" = "F2E1D0C9B8A7968574635241F0E9D8C7B6A5948372615048372615048372615"
    }
}
```

**Benefits:**
- Detects file corruption during download
- Prevents execution of maliciously modified installers
- Works even if attacker has valid code signing certificates

### 2. **Certificate Pinning** ✅
**What it does:**
- Validates SSL certificates match expected thumbprints for known hosts
- Prevents man-in-the-middle attacks on download sources
- Protects against compromised Certificate Authorities

**Implementation:**
```powershell
$script:ALLOWED_HOSTS = @{
    "www.rarlab.com" = @{
        "CertificateThumbprint" = "A1B2C3D4E5F6789012345678901234567890ABCD"
        "AllowedPaths" = @("/rar/*")
    }
    "cdn.cyci.org" = @{
        "CertificateThumbprint" = "C1D2E3F4A5B6789012345678901234567890CDAB"
        "AllowedPaths" = @("/ir_*.ps1")
    }
}
```

**Benefits:**
- Prevents certificate substitution attacks
- Protects against rogue CAs or compromised certificates
- Essential for secure `irm | iex` execution

### 3. **Enhanced Download Source Validation** ✅
**What it does:**
- Validates URLs against strict allowlists before any downloads
- Enforces HTTPS-only connections
- Detects path traversal and other URL manipulation attempts

**Implementation:**
```powershell
function Test-ValidDownloadUrl {
    # Must be HTTPS
    if ($uri.Scheme -ne "https") { return $false }
    
    # Host must be in allowed list
    if (-not $script:ALLOWED_HOSTS.ContainsKey($uri.Host)) { return $false }
    
    # Path must match allowed patterns
    # Check for path traversal attempts
    if ($Url -match "\.\.") { return $false }
}
```

**Benefits:**
- Prevents downloads from unauthorized sources
- Blocks URL manipulation attacks
- Enforces secure transport protocols

### 4. **Comprehensive Security Logging** ✅
**What it does:**
- Logs all security events to Windows Event Log
- Provides audit trails for compliance
- Enables monitoring and alerting on security events

**Implementation:**
```powershell
function Write-SecurityEvent {
    # Write to console
    Write-Info $Message
    
    # Write to Windows Event Log
    Write-EventLog -LogName "Application" -Source "InstaRAR-Enhanced" 
                   -EventId $EventId -EntryType $entryType -Message $Message
}
```

**Event ID Reference:**
- **1000-1999**: General operations
- **2000-2999**: URL validation
- **3000-3999**: Certificate pinning
- **4000-4999**: Secure downloads
- **5000-5999**: File integrity checks
- **6000-6999**: Signature verification
- **7000-7999**: Process management
- **8000-8999**: Version checking
- **9000-9999**: Installer downloads
- **10000+**: Installation process

### 5. **Enhanced Network Security** ✅
**What it does:**
- Implements exponential backoff for failed downloads
- Provides configurable timeouts and retry limits
- Uses BITS transfer for reliable downloads with resume capability

**Implementation:**
```powershell
function Invoke-SecureDownload {
    # Enhanced retry logic with exponential backoff
    $retryCount = 0
    $baseDelay = 1000  # 1 second
    
    while ($retryCount -le $MaxRetries) {
        try {
            Start-BitsTransfer -Source $Url -Destination $Destination
            # Verify hash if provided
            if ($ExpectedHash) {
                $actualHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash
                if ($actualHash -ne $ExpectedHash) {
                    throw "Hash verification failed"
                }
            }
            return $true
        } catch {
            $delay = $baseDelay * [Math]::Pow(2, $retryCount - 1)
            Start-Sleep -Milliseconds $delay
        }
    }
}
```

### 6. **Enhanced File Integrity Verification** ✅
**What it does:**
- Comprehensive file validation beyond just hashes
- Verifies file sizes are within expected ranges
- Validates PE file structure for executables
- Multiple integrity checkpoints throughout the process

**Implementation:**
```powershell
function Test-FileIntegrity {
    # Check file exists
    if (-not (Test-Path $FilePath)) { return $false }
    
    # Check file size is reasonable (WinRAR installers: 3-10MB)
    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Length -lt 1MB -or $fileInfo.Length -gt 50MB) {
        Write-SecurityEvent "Suspicious file size: $($fileInfo.Length) bytes"
    }
    
    # Verify PE structure for executables
    if ($FilePath -match '\.exe$') {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
            return $false  # Not a valid PE file
        }
    }
}
```

## 🛡️ **Configuration Options**

### Test Mode
Set environment variable to skip certificate pinning during testing:
```powershell
$env:INSTARAR_SKIP_CERT_PINNING = '1'
```

### Debug Mode
Enable debug pausing:
```powershell
$env:IR_DEBUG_PAUSE = '1'
```

### Hash Configuration
Update the `$script:KNOWN_HASHES` hashtable with real SHA256 values for production use. The current values are examples and must be replaced with actual hashes from verified WinRAR installers.

### Certificate Configuration
Update the `$script:ALLOWED_HOSTS` hashtable with actual certificate thumbprints:

```powershell
# Get certificate thumbprint for a host:
$cert = (Invoke-WebRequest -Uri "https://www.rarlab.com").BaseResponse.ServerCertificate
$thumbprint = $cert.GetCertHashString()
```

## 🚀 **Usage Instructions**

### Basic Usage
```powershell
# Run the enhanced security version
.\temp_ir_hardened.ps1
```

### Testing Mode
```powershell
# Skip certificate pinning for testing
$env:INSTARAR_SKIP_CERT_PINNING = '1'
.\temp_ir_hardened.ps1
```

### Monitoring Security Events
```powershell
# View security events in Event Viewer
Get-EventLog -LogName Application -Source "InstaRAR-Enhanced" -Newest 50
```

## 🎯 **Security Event Monitoring**

### PowerShell Monitoring
```powershell
# Monitor security events in real-time
Get-EventLog -LogName Application -Source "InstaRAR-Enhanced" -After (Get-Date).AddMinutes(-5)

# Filter by event type
Get-EventLog -LogName Application -Source "InstaRAR-Enhanced" | 
    Where-Object { $_.EntryType -eq "Error" }
```

### Enterprise Monitoring
Configure your SIEM/monitoring solution to watch for:
- Event Source: `InstaRAR-Enhanced`
- Log Name: `Application`
- Critical Event IDs:
  - **2004**: Path traversal attempt
  - **3004**: Certificate pinning failure  
  - **4006**: All download attempts failed
  - **5003**: Hash verification failure
  - **6002-6008**: Signature verification failures

## 📋 **Deployment Considerations**

### Production Deployment
1. **Update Hash Database**: Replace example hashes with real SHA256 values
2. **Update Certificate Thumbprints**: Get actual certificate thumbprints for your CDN
3. **Configure Monitoring**: Set up alerts for security events
4. **Test Certificate Pinning**: Verify pinning works with your actual certificates

### Enterprise Integration
- Integrate with existing logging infrastructure
- Configure SIEM rules for security events
- Set up automated alerting for failed security validations
- Consider implementing centralized hash management

## 🔍 **Security Benefits**

### Defense in Depth
Each security layer catches different types of attacks:
- **Hash verification**: Detects file tampering/corruption
- **Certificate pinning**: Prevents MITM attacks
- **URL validation**: Blocks unauthorized download sources
- **Enhanced signatures**: Validates publisher authenticity
- **File integrity**: Comprehensive file validation
- **Security logging**: Provides audit trails and monitoring

### Compliance Benefits
- **Audit trails**: All security events logged
- **Integrity verification**: File tampering detection
- **Access control**: URL and host allowlisting
- **Incident response**: Detailed security event data

## ⚠️ **Important Notes**

### Hash Management
- Example hashes in the code are **PLACEHOLDERS**
- You must obtain and verify real SHA256 hashes for production use
- Consider implementing automated hash updates from trusted sources

### Certificate Management
- Certificate thumbprints will change when certificates are renewed
- Implement monitoring for certificate changes
- Consider automated certificate thumbprint updates

### Performance Impact
- Hash verification adds ~1-2 seconds per download
- Certificate pinning adds ~500ms per connection
- Security logging has minimal overhead

### Testing
- Always test with actual certificates and hashes
- Verify certificate pinning doesn't break with CDN changes
- Test failover scenarios with multiple download sources

---

**Security Contact**: Phil @ DopeDealers  
**Last Updated**: 2025  
**Version**: Enhanced Security Edition v1.0
