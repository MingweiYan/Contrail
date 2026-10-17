[CmdletBinding()]
param(
    [string]$BindAddress,
    [int]$Port,
    [string]$AllowedHosts,
    [switch]$NoOpen,
    [switch]$SmokeTest,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Assert-LastExitCode {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE."
    }
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

if (-not $SkipBuild) {
    foreach ($CommandName in @("flutter", "dart")) {
        if ($null -eq (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
            throw "Required command is not available: $CommandName"
        }
    }
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ServerBinary = Join-Path $RepoRoot "build\contrail-server.exe"
$WebRoot = Join-Path $RepoRoot "build\web"
$EnvironmentNames = @(
    "CONTRAIL_BIND_ADDRESS",
    "CONTRAIL_WEB_ROOT",
    "PORT",
    "WEBDAV_GATEWAY_ALLOWED_HOSTS"
)
$PreviousEnvironment = @{}
foreach ($Name in $EnvironmentNames) {
    $PreviousEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name, "Process")
}

$ServerProcess = $null
Push-Location $RepoRoot
try {
    if ($SkipBuild) {
        if (-not (Test-Path -LiteralPath $ServerBinary -PathType Leaf)) {
            throw "Prebuilt Contrail server is missing: $ServerBinary"
        }
        $WebIndex = Join-Path $WebRoot "index.html"
        if (-not (Test-Path -LiteralPath $WebIndex -PathType Leaf)) {
            throw "Prebuilt Contrail Web application is missing: $WebIndex"
        }
    } else {
        Write-Host "==> Installing locked Flutter dependencies"
        & flutter pub get --enforce-lockfile
        Assert-LastExitCode "flutter pub get"

        Write-Host "==> Building the integrated Web application"
        & flutter build web --release --no-wasm-dry-run `
            --dart-define=WEBDAV_GATEWAY_URL=/api/webdav
        Assert-LastExitCode "flutter build web"

        Write-Host "==> Compiling the integrated Web server"
        & dart compile exe server/bin/contrail_server.dart -o $ServerBinary
        Assert-LastExitCode "dart compile exe"
    }

    $env:CONTRAIL_BIND_ADDRESS = $BindAddress
    $env:CONTRAIL_WEB_ROOT = $WebRoot
    $env:PORT = $ServicePort.ToString()
    $env:WEBDAV_GATEWAY_ALLOWED_HOSTS = $AllowedHosts

    $ConnectHost = $BindAddress
    if (@("0.0.0.0", "::", "[::]") -contains $ConnectHost) {
        $ConnectHost = "127.0.0.1"
    }
    $UrlHost = $ConnectHost
    if ($UrlHost.Contains(":") -and -not $UrlHost.StartsWith("[")) {
        $UrlHost = "[$UrlHost]"
    }
    $ServiceUrl = "http://${UrlHost}:$ServicePort"

    Write-Host "==> Starting Contrail on $ServiceUrl"
    $ServerProcess = Start-Process `
        -FilePath $ServerBinary `
        -WorkingDirectory $RepoRoot `
        -NoNewWindow `
        -PassThru

    $HealthUrl = "$ServiceUrl/healthz"
    $Ready = $false
    for ($Attempt = 0; $Attempt -lt 100; $Attempt++) {
        $ServerProcess.Refresh()
        if ($ServerProcess.HasExited) {
            throw "Contrail exited before becoming healthy (status $($ServerProcess.ExitCode))."
        }
        try {
            $Response = Invoke-WebRequest `
                -Uri $HealthUrl `
                -UseBasicParsing `
                -TimeoutSec 2
            if ($Response.StatusCode -eq 200 -and $Response.Content -match '"status"\s*:\s*"ok"') {
                $Ready = $true
                break
            }
        } catch {
            # The service can refuse connections while the Dart runtime starts.
        }
        Start-Sleep -Milliseconds 200
    }

    if (-not $Ready) {
        throw "Contrail did not become healthy at $HealthUrl."
    }

    $AppUrl = "$ServiceUrl/"
    Write-Host "Contrail is ready: $AppUrl"

    if ($SmokeTest) {
        Write-Host "Cross-platform deployment smoke test passed."
        return
    }

    if (-not $NoOpen) {
        Start-Process $AppUrl
    }

    Write-Host "Press Ctrl+C to stop Contrail."
    $ServerProcess.WaitForExit()
    if ($ServerProcess.ExitCode -ne 0) {
        throw "Contrail exited with status $($ServerProcess.ExitCode)."
    }
} finally {
    if ($null -ne $ServerProcess) {
        $ServerProcess.Refresh()
        if (-not $ServerProcess.HasExited) {
            Stop-Process -Id $ServerProcess.Id -ErrorAction SilentlyContinue
            $ServerProcess.WaitForExit(5000) | Out-Null
        }
        $ServerProcess.Dispose()
    }
    foreach ($Name in $EnvironmentNames) {
        [Environment]::SetEnvironmentVariable(
            $Name,
            $PreviousEnvironment[$Name],
            "Process"
        )
    }
    Pop-Location
}
