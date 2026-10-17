[CmdletBinding()]
param(
    [string]$RuntimeDirectory,
    [switch]$OpenLog
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($RuntimeDirectory)) {
    $RuntimeDirectory = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_RUNTIME_DIR)) {
        Join-Path $RepoRoot "runtime"
    } elseif ([IO.Path]::IsPathRooted($env:CONTRAIL_RUNTIME_DIR)) {
        $env:CONTRAIL_RUNTIME_DIR
    } else {
        Join-Path $RepoRoot $env:CONTRAIL_RUNTIME_DIR
    }
} elseif (-not [IO.Path]::IsPathRooted($RuntimeDirectory)) {
    $RuntimeDirectory = Join-Path $RepoRoot $RuntimeDirectory
}
$RuntimeDirectory = [IO.Path]::GetFullPath($RuntimeDirectory)

$PidFile = Join-Path $RuntimeDirectory "contrail.pid"
$UrlFile = Join-Path $RuntimeDirectory "contrail.url"
$ServerBinary = [IO.Path]::GetFullPath((Join-Path $RepoRoot "build\contrail-server.exe"))
$LogFile = if ([string]::IsNullOrWhiteSpace($env:CONTRAIL_LOG_FILE)) {
    Join-Path $RuntimeDirectory "contrail.log"
} elseif ([IO.Path]::IsPathRooted($env:CONTRAIL_LOG_FILE)) {
    $env:CONTRAIL_LOG_FILE
} else {
    Join-Path $RepoRoot $env:CONTRAIL_LOG_FILE
}

if (-not (Test-Path -LiteralPath $PidFile -PathType Leaf)) {
    Write-Host "Contrail is not running (no PID file at $PidFile)."
    return
}
$StoredProcessId = 0
$RawProcessId = (Get-Content -LiteralPath $PidFile -Raw).Trim()
if (-not [int]::TryParse($RawProcessId, [ref]$StoredProcessId)) {
    Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
    throw "Removed invalid Contrail PID file: $PidFile"
}
$ServerProcess = Get-Process -Id $StoredProcessId -ErrorAction SilentlyContinue
if ($null -eq $ServerProcess) {
    Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
    Write-Host "Contrail is already stopped; removed stale runtime state."
    return
}

try {
    $ActualPath = $ServerProcess.Path
    if ([string]::IsNullOrWhiteSpace($ActualPath) -or -not [string]::Equals(
        [IO.Path]::GetFullPath($ActualPath),
        $ServerBinary,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
        throw "PID $StoredProcessId does not belong to this Contrail server; it was not stopped."
    }

    Write-Host "==> Stopping Contrail (PID $StoredProcessId)"
    Stop-Process -Id $StoredProcessId -Force
    $ServerProcess.WaitForExit(10000) | Out-Null
    Remove-Item -LiteralPath $PidFile, $UrlFile -Force -ErrorAction SilentlyContinue
    Write-Host "Contrail stopped."
    if ($OpenLog -and (Test-Path -LiteralPath $LogFile)) {
        Invoke-Item -LiteralPath $LogFile
    }
} finally {
    $ServerProcess.Dispose()
}
