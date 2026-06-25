# Converts Net-SNMP binaries from ../thirdparty/bin to Base64 text files in ../thirdparty/b64.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $PSCommandPath
}

$toolsDir = Split-Path -Parent $scriptDir
$binDir = Join-Path $toolsDir "thirdparty\bin"
$b64Dir = Join-Path $toolsDir "thirdparty\b64"

if (-not (Test-Path -LiteralPath $binDir)) {
    throw "Binary-Verzeichnis wurde nicht gefunden: $binDir"
}

if (-not (Test-Path -LiteralPath $b64Dir)) {
    New-Item -Path $b64Dir -ItemType Directory -Force | Out-Null
}

foreach ($fileName in @("snmpwalk.exe", "netsnmp.dll")) {
    $sourcePath = Join-Path $binDir $fileName
    $targetPath = Join-Path $b64Dir "$fileName.b64"

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Binary-Datei wurde nicht gefunden: $sourcePath"
    }

    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $sourcePath).Path)
    $base64 = [Convert]::ToBase64String($bytes)

    [System.IO.File]::WriteAllText(
        $targetPath,
        $base64,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host "Erstellt: $targetPath"
}
