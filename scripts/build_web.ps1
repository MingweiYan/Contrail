[CmdletBinding()]
param(
    [switch]$SkipPubGet
)

$ErrorActionPreference = "Stop"

function Assert-LastExitCode {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE."
    }
}

foreach ($CommandName in @("flutter", "dart")) {
    if ($null -eq (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Required build command is not available: $CommandName"
    }
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ServerBinary = Join-Path $RepoRoot "build\contrail-server.exe"

Push-Location $RepoRoot
try {
    if (-not $SkipPubGet) {
        Write-Host "==> Installing locked Flutter dependencies"
        & flutter pub get --enforce-lockfile
        Assert-LastExitCode "flutter pub get"
    }

    Write-Host "==> Building the integrated Web application"
    & flutter build web --release --no-pub --no-wasm-dry-run `
        --dart-define=WEBDAV_GATEWAY_URL=/api/webdav
    Assert-LastExitCode "flutter build web"

    Write-Host "==> Compiling the integrated Web server"
    & dart compile exe server/bin/contrail_server.dart -o $ServerBinary
    Assert-LastExitCode "dart compile exe"

    Write-Host "Contrail Web build completed."
} finally {
    Pop-Location
}
