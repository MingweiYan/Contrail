[CmdletBinding()]
param(
    [string]$BindAddress,
    [int]$Port,
    [string]$AllowedHosts,
    [string]$RuntimeDirectory,
    [string]$LogFile,
    [ValidateSet("debug", "info", "warn", "warning", "error", "off")]
    [string]$LogLevel,
    [int]$LogMaxMegabytes,
    [int]$LogBackups,
    [switch]$OpenLog,
    [switch]$NoOpen,
    [switch]$Rebuild,
    [switch]$SkipBuild,
    [switch]$SmokeTest
)

$ErrorActionPreference = "Stop"

function Resolve-ContrailPath {
    param(
        [string]$Path,
        [string]$BasePath
    )
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-ExpectedProcess {
    param(
        [Diagnostics.Process]$Process,
        [string]$ExpectedPath
    )
    try {
        $ActualPath = $Process.Path
        if ([string]::IsNullOrWhiteSpace($ActualPath)) {
            return $false
        }
        return [string]::Equals(
            [IO.Path]::GetFullPath($ActualPath),
            [IO.Path]::GetFullPath($ExpectedPath),
            [StringComparison]::OrdinalIgnoreCase
        )
    } catch {
        return $false
    }
}

if ($SkipBuild -and $Rebuild) {
    throw "-SkipBuild and -Rebuild cannot be used together."
}
if ([string]::IsNullOrWhiteSpace($BindAddress)) {
    $BindAddress = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_BIND_ADDRESS)) {
        "127.0.0.1"
    } else {
        $env:CONTRAIL_BIND_ADDRESS
    }
}
if (-not $PSBoundParameters.ContainsKey("Port")) {
    if ([string]::IsNullOrWhiteSpace($env:PORT)) {
        $ServicePort = 27831
    } else {
        $ParsedPort = 0
        if (-not [int]::TryParse($env:PORT, [ref]$ParsedPort)) {
            throw "PORT must be an integer: $($env:PORT)"
        }
        $ServicePort = $ParsedPort
    }
} else {
    $ServicePort = $Port
}
if ($ServicePort -lt 1 -or $ServicePort -gt 65535) {
    throw "Port must be an integer from 1 to 65535: $ServicePort"
}
if ([string]::IsNullOrWhiteSpace($AllowedHosts)) {
    $AllowedHosts = if ([string]::IsNullOrWhiteSpace($env:WEBDAV_GATEWAY_ALLOWED_HOSTS)) {
        "dav.jianguoyun.com"
    } else {
        $env:WEBDAV_GATEWAY_ALLOWED_HOSTS
    }
}
if ([string]::IsNullOrWhiteSpace(($AllowedHosts -replace "[,\s]", ""))) {
    throw "At least one WebDAV host must be allowed."
}
if ([string]::IsNullOrWhiteSpace($LogLevel)) {
    $LogLevel = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_LOG_LEVEL)) {
        "info"
    } else {
        $env:CONTRAIL_LOG_LEVEL.ToLowerInvariant()
    }
}
if (@("debug", "info", "warn", "warning", "error", "off") -notcontains $LogLevel) {
    throw "Log level must be debug, info, warn, error, or off: $LogLevel"
}
if ($PSBoundParameters.ContainsKey("LogMaxMegabytes")) {
    if ($LogMaxMegabytes -lt 1 -or $LogMaxMegabytes -gt 2048) {
        throw "LogMaxMegabytes must be from 1 to 2048: $LogMaxMegabytes"
    }
    $LogMaxBytes = $LogMaxMegabytes * 1024 * 1024
} elseif ([string]::IsNullOrWhiteSpace($env:CONTRAIL_LOG_MAX_BYTES)) {
    $LogMaxBytes = 10 * 1024 * 1024
} else {
    $LogMaxBytes = 0L
    if (-not [long]::TryParse($env:CONTRAIL_LOG_MAX_BYTES, [ref]$LogMaxBytes) -or $LogMaxBytes -lt 1024) {
        throw "CONTRAIL_LOG_MAX_BYTES must be an integer of at least 1024."
    }
}
if (-not $PSBoundParameters.ContainsKey("LogBackups")) {
    if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_LOG_BACKUP_COUNT)) {
        $LogBackups = 3
    } elseif (-not [int]::TryParse($env:CONTRAIL_LOG_BACKUP_COUNT, [ref]$LogBackups)) {
        throw "CONTRAIL_LOG_BACKUP_COUNT must be an integer."
    }
}
if ($LogBackups -lt 0 -or $LogBackups -gt 100) {
    throw "LogBackups must be from 0 to 100: $LogBackups"
}
if ($null -eq (Get-Command "curl.exe" -ErrorAction SilentlyContinue)) {
    throw "Required command is not available: curl.exe"
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ServerBinary = Join-Path $RepoRoot "build\contrail-server.exe"
$WebRoot = Join-Path $RepoRoot "build\web"
$WebIndex = Join-Path $WebRoot "index.html"
$ArtifactsReady = (Test-Path -LiteralPath $ServerBinary -PathType Leaf) -and
    (Test-Path -LiteralPath $WebIndex -PathType Leaf)

if ($SkipBuild) {
    if (-not $ArtifactsReady) {
        throw "Compiled Contrail artifacts are missing; -SkipBuild forbids rebuilding."
    }
} elseif ($Rebuild -or -not $ArtifactsReady) {
    & (Join-Path $PSScriptRoot "build_web.ps1")
}

if ([string]::IsNullOrWhiteSpace($RuntimeDirectory)) {
    $RuntimeDirectory = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_RUNTIME_DIR)) {
        Join-Path $RepoRoot "runtime"
    } else {
        Resolve-ContrailPath $env:CONTRAIL_RUNTIME_DIR $RepoRoot
    }
} else {
    $RuntimeDirectory = Resolve-ContrailPath $RuntimeDirectory $RepoRoot
}
New-Item -ItemType Directory -Path $RuntimeDirectory -Force | Out-Null
if ([string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_LOG_FILE)) {
        Join-Path $RuntimeDirectory "contrail.log"
    } else {
        Resolve-ContrailPath $env:CONTRAIL_LOG_FILE $RepoRoot
    }
} else {
    $LogFile = Resolve-ContrailPath $LogFile $RepoRoot
}
New-Item -ItemType Directory -Path (Split-Path -Parent $LogFile) -Force | Out-Null

$PidFile = Join-Path $RuntimeDirectory "contrail.pid"
$UrlFile = Join-Path $RuntimeDirectory "contrail.url"
$LaunchOutput = Join-Path $RuntimeDirectory "contrail-launch.out.log"
$LaunchError = Join-Path $RuntimeDirectory "contrail-launch.error.log"

if (Test-Path -LiteralPath $PidFile -PathType Leaf) {
    $StoredProcessId = 0
    $RawProcessId = (Get-Content -LiteralPath $PidFile -Raw).Trim()
    if ([int]::TryParse($RawProcessId, [ref]$StoredProcessId)) {
        $ExistingProcess = Get-Process -Id $StoredProcessId -ErrorAction SilentlyContinue
        if ($null -ne $ExistingProcess) {
            if (Test-ExpectedProcess $ExistingProcess $ServerBinary) {
                $ExistingUrl = if (Test-Path -LiteralPath $UrlFile) {
                    (Get-Content -LiteralPath $UrlFile -Raw).Trim()
                } else {
                    ""
                }
                Write-Host "Contrail is already running (PID $StoredProcessId$(if ($ExistingUrl) { ", $ExistingUrl" }))."
                Write-Host "Stop it with: .\scripts\stop_web.ps1"
                $ExistingProcess.Dispose()
                return
            }
            $ExistingProcess.Dispose()
            throw "Refusing to reuse PID $StoredProcessId because it belongs to another process."
        }
    }
    Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
}

$ConnectHost = $BindAddress
if (@("0.0.0.0", "::", "[::]") -contains $ConnectHost) {
    $ConnectHost = "127.0.0.1"
}
$UrlHost = $ConnectHost
if ($UrlHost.Contains(":") -and -not $UrlHost.StartsWith("[")) {
    $UrlHost = "[$UrlHost]"
}
$ServiceUrl = "http://${UrlHost}:$ServicePort"

$EnvironmentNames = @(
    "CONTRAIL_BIND_ADDRESS",
    "CONTRAIL_WEB_ROOT",
    "PORT",
    "WEBDAV_GATEWAY_ALLOWED_HOSTS",
    "CONTRAIL_LOG_LEVEL",
    "CONTRAIL_LOG_FILE",
    "CONTRAIL_LOG_MAX_BYTES",
    "CONTRAIL_LOG_BACKUP_COUNT"
)
$PreviousEnvironment = @{}
foreach ($Name in $EnvironmentNames) {
    $PreviousEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name, "Process")
}

$ServerProcess = $null
$CleanupStartedProcess = $true
try {
    $env:CONTRAIL_BIND_ADDRESS = $BindAddress
    $env:CONTRAIL_WEB_ROOT = $WebRoot
    $env:PORT = $ServicePort.ToString()
    $env:WEBDAV_GATEWAY_ALLOWED_HOSTS = $AllowedHosts
    $env:CONTRAIL_LOG_LEVEL = $LogLevel
    $env:CONTRAIL_LOG_FILE = $LogFile
    $env:CONTRAIL_LOG_MAX_BYTES = $LogMaxBytes.ToString()
    $env:CONTRAIL_LOG_BACKUP_COUNT = $LogBackups.ToString()

    Set-Content -LiteralPath $LaunchOutput -Value "" -Encoding ascii
    Set-Content -LiteralPath $LaunchError -Value "" -Encoding ascii
    Write-Host "==> Starting Contrail in the background on $ServiceUrl"
    $ServerProcess = Start-Process `
        -FilePath $ServerBinary `
        -WorkingDirectory $RepoRoot `
        -WindowStyle Hidden `
        -RedirectStandardOutput $LaunchOutput `
        -RedirectStandardError $LaunchError `
        -PassThru
    Set-Content -LiteralPath $PidFile -Value $ServerProcess.Id -Encoding ascii
    Set-Content -LiteralPath $UrlFile -Value $ServiceUrl -Encoding ascii

    $HealthUrl = "$ServiceUrl/healthz"
    $Ready = $false
    for ($Attempt = 0; $Attempt -lt 100; $Attempt++) {
        $ServerProcess.Refresh()
        if ($ServerProcess.HasExited) {
            throw "Contrail exited before becoming healthy (status $($ServerProcess.ExitCode))."
        }
        try {
            $HealthBody = & curl.exe --fail --silent --max-time 2 $HealthUrl
            if ($LASTEXITCODE -eq 0 -and $HealthBody -match '"status"\s*:\s*"ok"') {
                $Ready = $true
                break
            }
        } catch {
            # The service can refuse connections while the runtime starts.
        }
        Start-Sleep -Milliseconds 200
    }
    if (-not $Ready) {
        throw "Contrail did not become healthy at $HealthUrl."
    }

    Write-Host "Contrail is ready: $ServiceUrl/"
    Write-Host "Service log: $LogFile"
    if ($SmokeTest) {
        Write-Host "Cross-platform deployment smoke test passed."
        return
    }

    $CleanupStartedProcess = $false
    if (-not $NoOpen) {
        Start-Process "$ServiceUrl/"
    }
    if ($OpenLog -and (Test-Path -LiteralPath $LogFile)) {
        Invoke-Item -LiteralPath $LogFile
    }
    Write-Host "Contrail continues running in the background (PID $($ServerProcess.Id))."
    Write-Host "Stop it with: .\scripts\stop_web.ps1"
} finally {
    if ($CleanupStartedProcess -and $null -ne $ServerProcess) {
        $ServerProcess.Refresh()
        if (-not $ServerProcess.HasExited -and (Test-ExpectedProcess $ServerProcess $ServerBinary)) {
            Stop-Process -Id $ServerProcess.Id -Force -ErrorAction SilentlyContinue
            $ServerProcess.WaitForExit(5000) | Out-Null
        }
        Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $ServerProcess) {
        $ServerProcess.Dispose()
    }
    foreach ($Name in $EnvironmentNames) {
        [Environment]::SetEnvironmentVariable(
            $Name,
            $PreviousEnvironment[$Name],
            "Process"
        )
    }
}
