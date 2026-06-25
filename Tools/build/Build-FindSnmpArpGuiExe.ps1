# Builds ../Find-SnmpArp-GUI.ps1 into an executable with ps2exe.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $PSCommandPath
}

$toolsDir = Split-Path -Parent $scriptDir
$sourceScript = Join-Path $toolsDir "Find-SnmpArp-GUI.ps1"
$b64Dir = Join-Path $toolsDir "thirdparty\b64"
$outputDir = Join-Path $toolsDir "exe"
$outputExe = Join-Path $outputDir "Find-SnmpArp-GUI.exe"

if (-not (Test-Path -LiteralPath $sourceScript)) {
    throw "Quellskript wurde nicht gefunden: $sourceScript"
}

if (-not (Get-Command "ps2exe" -ErrorAction SilentlyContinue)) {
    throw "ps2exe wurde nicht gefunden. Bitte ps2exe installieren oder in den PATH aufnehmen."
}

$snmpWalkB64 = Join-Path $b64Dir "snmpwalk.exe.b64"
$netSnmpDllB64 = Join-Path $b64Dir "netsnmp.dll.b64"

foreach ($file in @($snmpWalkB64, $netSnmpDllB64)) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Einzubettende Base64-Datei wurde nicht gefunden: $file"
    }
}

if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

if (Test-Path -LiteralPath $outputExe) {
    try {
        Remove-Item -LiteralPath $outputExe -Force -ErrorAction Stop
    }
    catch {
        throw "Vorhandene EXE konnte nicht entfernt werden. Bitte laufende Instanzen schliessen und erneut starten: $outputExe"
    }
}

$embeddedFiles = @{
    "%LOCALAPPDATA%\SnmpArpGui\b64\snmpwalk.exe.b64" = $snmpWalkB64
    "%LOCALAPPDATA%\SnmpArpGui\b64\netsnmp.dll.b64"  = $netSnmpDllB64
}

ps2exe $sourceScript $outputExe -noConsole -STA -embedFiles $embeddedFiles

if (-not (Test-Path -LiteralPath $outputExe)) {
    throw "EXE wurde nicht erstellt: $outputExe"
}

Write-Host "Erstellt: $outputExe"
