<#
.SYNOPSIS
  Builds the signed Play Store artifact (.aab) for the Unique Diagnostic customer app.

.DESCRIPTION
  Play requires an App Bundle, not an APK — the sibling build_release.sh predates
  that and only emits APKs, so use this script for anything destined for the store.

  Production config is injected at build time via --dart-define and is never
  committed:
    API_BASE_URL  the live HTTPS API root, e.g. https://api.example.com/api/v1
    CERT_PINS     optional comma-separated base64 SHA-256 leaf + backup-CA pins

  Signing comes from android/key.properties (gitignored). Without that file
  Gradle silently falls back to the debug key and Play will reject the upload,
  so this script refuses to run rather than hand you a dud bundle.

.PARAMETER ApiBaseUrl
  The production API root. Must be HTTPS — Android blocks cleartext by default.

.EXAMPLE
  .\scripts\build_release.ps1 -ApiBaseUrl "https://api.uniquediagnostic.in/api/v1"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,

    [string]$CertPins = "",

    [string]$FlutterBin = "D:\flutter\bin\flutter.bat",

    # Also emit a universal APK for sideloaded QA builds.
    [switch]$AlsoApk
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

if ($ApiBaseUrl -notmatch '^https://') {
    throw "ApiBaseUrl must be HTTPS. Android blocks cleartext traffic, and Play rejects apps that require it."
}

if (-not (Test-Path "$projectRoot\android\key.properties")) {
    throw "android/key.properties not found. Release would be signed with the debug key and rejected by Play."
}

$debugInfoDir = "$projectRoot\build\debug-info"

$defines = @("--dart-define=API_BASE_URL=$ApiBaseUrl")
if ($CertPins) { $defines += "--dart-define=CERT_PINS=$CertPins" }

# flutter.bat writes progress to stderr, which Windows PowerShell turns into a
# terminating NativeCommandError under ErrorActionPreference=Stop. Drop to
# Continue around the native calls and gate on $LASTEXITCODE instead.
function Invoke-Flutter {
    param([string[]]$FlutterArgs, [string]$What)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $FlutterBin @FlutterArgs
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit $LASTEXITCODE)" }
}

Write-Host "Building App Bundle against $ApiBaseUrl ..." -ForegroundColor Cyan
Invoke-Flutter -What "appbundle build" -FlutterArgs (
    @("build", "appbundle", "--release", "--obfuscate",
      "--split-debug-info=$debugInfoDir\android") + $defines)

if ($AlsoApk) {
    Write-Host "Building universal APK for QA ..." -ForegroundColor Cyan
    Invoke-Flutter -What "apk build" -FlutterArgs (
        @("build", "apk", "--release", "--obfuscate",
          "--split-debug-info=$debugInfoDir\android") + $defines)
}

$aab = "$projectRoot\build\app\outputs\bundle\release\app-release.aab"
Write-Host ""
Write-Host "Bundle:  $aab" -ForegroundColor Green
if (Test-Path $aab) {
    Write-Host "Size:    $([math]::Round((Get-Item $aab).Length / 1MB, 2)) MB"
}
Write-Host "Symbols: $debugInfoDir\android" -ForegroundColor Yellow
Write-Host "         Obfuscated builds need these to deobfuscate Play crash reports."
Write-Host "         Archive them per release; never ship them."
