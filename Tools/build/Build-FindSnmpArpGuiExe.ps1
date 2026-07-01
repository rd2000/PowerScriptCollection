# Builds ../Find-SnmpArp-GUI.ps1 into an executable with ps2exe.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $PSCommandPath
}

$toolsDir = Split-Path -Parent $scriptDir
$sourceScript = Join-Path $toolsDir "Find-SnmpArp-GUI.ps1"
$b64Dir = Join-Path $toolsDir "thirdparty\b64"
$configDir = Join-Path $toolsDir "config"
$outputDir = Join-Path $toolsDir "exe"
$outputExe = Join-Path $outputDir "Find-SnmpArp-GUI.exe"
$metadataPath = Join-Path $scriptDir "FindSnmpArpGuiExe.metadata.json"

if (-not (Test-Path -LiteralPath $sourceScript)) {
    throw "Quellskript wurde nicht gefunden: $sourceScript"
}

if (-not (Test-Path -LiteralPath $metadataPath)) {
    throw "EXE-Metadaten wurden nicht gefunden: $metadataPath"
}

if (-not (Get-Command "ps2exe" -ErrorAction SilentlyContinue)) {
    throw "ps2exe wurde nicht gefunden. Bitte ps2exe installieren oder in den PATH aufnehmen."
}

$snmpWalkB64 = Join-Path $b64Dir "snmpwalk.exe.b64"
$netSnmpDllB64 = Join-Path $b64Dir "netsnmp.dll.b64"
$routerConfig = Join-Path $configDir "routers.json"
$macVendorsConfig = Join-Path $configDir "macvendors.csv"

foreach ($file in @($snmpWalkB64, $netSnmpDllB64, $routerConfig, $macVendorsConfig)) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Einzubettende Datei wurde nicht gefunden: $file"
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
    "%LOCALAPPDATA%\SnmpArpGui\config\routers.json"  = $routerConfig
    "%LOCALAPPDATA%\SnmpArpGui\config\macvendors.csv" = $macVendorsConfig
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$metadataArguments = @{}
foreach ($propertyName in @("title", "description", "company", "version", "product")) {
    if (($metadata.PSObject.Properties.Name -contains $propertyName) -and
        -not [string]::IsNullOrWhiteSpace($metadata.$propertyName)) {
        $metadataArguments[$propertyName] = $metadata.$propertyName
    }
}

if (($metadataArguments.ContainsKey("version")) -and
    ($metadataArguments["version"] -notmatch '^\d+\.\d+\.\d+\.\d+$')) {
    throw "EXE-Version muss vier numerische Bestandteile haben, z.B. 1.0.0.0: $($metadataArguments["version"])"
}

ps2exe $sourceScript $outputExe -noConsole -STA -embedFiles $embeddedFiles @metadataArguments

if (-not (Test-Path -LiteralPath $outputExe)) {
    throw "EXE wurde nicht erstellt: $outputExe"
}

Write-Host "Erstellt: $outputExe"
