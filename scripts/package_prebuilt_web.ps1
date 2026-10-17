[CmdletBinding()]
param(
    [ValidateSet("x64")]
    [string]$Architecture = "x64",
    [string]$OutputDirectory = "dist"
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not [IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $RepoRoot $OutputDirectory
}

$ServerBinary = Join-Path $RepoRoot "build\contrail-server.exe"
$WebRoot = Join-Path $RepoRoot "build\web"
$WebIndex = Join-Path $WebRoot "index.html"
if (-not (Test-Path -LiteralPath $ServerBinary -PathType Leaf)) {
    throw "Native Contrail server is missing: $ServerBinary"
}
if (-not (Test-Path -LiteralPath $WebIndex -PathType Leaf)) {
    throw "Contrail Web build is missing: $WebIndex"
}

$BundleName = "Contrail-Windows-$Architecture"
$BundleDirectory = Join-Path $OutputDirectory $BundleName
$ArchivePath = Join-Path $OutputDirectory "$BundleName.zip"
if ((Test-Path -LiteralPath $BundleDirectory) -or (Test-Path -LiteralPath $ArchivePath)) {
    throw "Release output already exists: $BundleDirectory or $ArchivePath"
}

$BuildDirectory = Join-Path $BundleDirectory "build"
$ScriptsDirectory = Join-Path $BundleDirectory "scripts"
New-Item -ItemType Directory -Path $BuildDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $ScriptsDirectory -Force | Out-Null

Copy-Item -LiteralPath $WebRoot -Destination $BuildDirectory -Recurse
Copy-Item -LiteralPath $ServerBinary -Destination (Join-Path $BuildDirectory "contrail-server.exe")
Copy-Item `
    -LiteralPath (Join-Path $RepoRoot "scripts\deploy_web.ps1") `
    -Destination (Join-Path $ScriptsDirectory "deploy_web.ps1")
Copy-Item `
    -LiteralPath (Join-Path $RepoRoot "scripts\release\start_prebuilt_web_windows.cmd") `
    -Destination (Join-Path $BundleDirectory "Start Contrail.cmd")
Copy-Item `
    -LiteralPath (Join-Path $RepoRoot "scripts\release\PREBUILT_README.txt") `
    -Destination (Join-Path $BundleDirectory "README.txt")
Copy-Item `
    -LiteralPath (Join-Path $RepoRoot "LICENSE") `
    -Destination (Join-Path $BundleDirectory "LICENSE")

Compress-Archive -LiteralPath $BundleDirectory -DestinationPath $ArchivePath
Write-Host "Created prebuilt release bundle: $ArchivePath"
