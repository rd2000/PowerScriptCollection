# Find-SnmpArp-GUI.ps1
# GUI fuer SNMP-ARP-Suche mit ausgelagerten Net-SNMP-Base64-Dateien
# Ausgabe: IPv4, DNSName, MAC, Vendor, Interface, Description, SwitchIP

# ---------------------------------------------------------------------------
# Drittanbieter-Base64-Dateien
# ---------------------------------------------------------------------------
# Beim EXE-Build werden snmpwalk.exe.b64 und netsnmp.dll.b64 per ps2exe eingebettet.
# ps2exe extrahiert sie beim Start nach LocalAppData, danach werden daraus die Binaries erstellt.
# ---------------------------------------------------------------------------
# GUI / Initialisierung
# ---------------------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data

# Bei direktem Start als .ps1 automatisch mit STA neu starten.
# Bei spaeterer EXE-Konvertierung bitte beim Konvertieren STA aktivieren, z.B. ps2exe mit -STA.
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $currentProcessPath = (Get-Process -Id $PID).Path
    $processName = [System.IO.Path]::GetFileName($currentProcessPath)

    if ($processName -in @('powershell.exe', 'pwsh.exe')) {
        Start-Process -FilePath $currentProcessPath -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-STA',
            '-File', "`"$PSCommandPath`""
        )
        exit
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Die Anwendung laeuft nicht im STA-Modus. Bitte die EXE mit STA-Option erstellen, z.B. ps2exe -STA.",
            "STA-Modus erforderlich",
            "OK",
            "Error"
        ) | Out-Null
        exit
    }
}

function Read-Base64File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Base64-Datei wurde nicht gefunden: $Path"
    }

    $base64 = Get-Content -LiteralPath $Path -Raw

    if ([string]::IsNullOrWhiteSpace($base64)) {
        throw "Base64-Datei ist leer: $Path"
    }

    return ($base64 -replace '\s', '')
}

function Write-Base64File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base64,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Base64)) {
        throw "Base64-Daten fehlen fuer: $Path"
    }

    $bytes = [Convert]::FromBase64String(($Base64 -replace '\s', ''))
    $writeFile = $true

    if (Test-Path -LiteralPath $Path) {
        try {
            $existing = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($existing.Length -eq $bytes.Length) {
                $writeFile = $false
            }
        }
        catch {
            $writeFile = $true
        }
    }

    if ($writeFile) {
        [System.IO.File]::WriteAllBytes($Path, $bytes)
    }
}

function Get-ApplicationBaseDirectories {
    $directories = New-Object 'System.Collections.Generic.List[string]'
    $currentDirectory = (Get-Location).Path

    foreach ($path in @($PSScriptRoot, $PSCommandPath, $currentDirectory, [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        try {
            $directory = $path
            if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
                $directory = Split-Path -Parent $path
            }

            if (-not [string]::IsNullOrWhiteSpace($directory) -and -not $directories.Contains($directory)) {
                $directories.Add($directory)
            }

            $toolsDirectory = Join-Path $directory "Tools"
            if ((Test-Path -LiteralPath $toolsDirectory -PathType Container) -and -not $directories.Contains($toolsDirectory)) {
                $directories.Add($toolsDirectory)
            }
        }
        catch {
            continue
        }
    }

    return $directories.ToArray()
}

function Resolve-SnmpBase64Directory {
    $embeddedDir = Join-Path $env:LOCALAPPDATA "SnmpArpGui\b64"
    if (
        (Test-Path -LiteralPath (Join-Path $embeddedDir "snmpwalk.exe.b64")) -and
        (Test-Path -LiteralPath (Join-Path $embeddedDir "netsnmp.dll.b64"))
    ) {
        return $embeddedDir
    }

    # Fallback fuer den direkten Start als .ps1 im Repository.
    foreach ($baseDir in (Get-ApplicationBaseDirectories)) {
        $candidate = Join-Path $baseDir "thirdparty\b64"

        if (
            (Test-Path -LiteralPath (Join-Path $candidate "snmpwalk.exe.b64")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "netsnmp.dll.b64"))
        ) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Net-SNMP-Base64-Dateien wurden nicht gefunden. Erwartet wird %LOCALAPPDATA%\SnmpArpGui\b64 oder Tools\thirdparty\b64 mit snmpwalk.exe.b64 und netsnmp.dll.b64."
}

function Resolve-RouterConfigDirectory {
    # Beim direkten Start als .ps1 im Repository soll die gepflegte Projektdatei
    # Vorrang vor einer eventuell aelteren eingebetteten EXE-Kopie haben.
    foreach ($baseDir in (Get-ApplicationBaseDirectories)) {
        $candidate = Join-Path $baseDir "config"

        if (Test-Path -LiteralPath (Join-Path $candidate "routers.json")) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $embeddedDir = Join-Path $env:LOCALAPPDATA "SnmpArpGui\config"
    if (Test-Path -LiteralPath (Join-Path $embeddedDir "routers.json")) {
        return $embeddedDir
    }

    return $null
}

function Resolve-MacVendorConfigPath {
    # Beim direkten Start als .ps1 im Repository soll die gepflegte Projektdatei
    # Vorrang vor einer eventuell aelteren eingebetteten EXE-Kopie haben.
    foreach ($baseDir in (Get-ApplicationBaseDirectories)) {
        $candidate = Join-Path $baseDir "config\macvendors.csv"

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $embeddedPath = Join-Path $env:LOCALAPPDATA "SnmpArpGui\config\macvendors.csv"
    if (Test-Path -LiteralPath $embeddedPath -PathType Leaf) {
        return $embeddedPath
    }

    return $null
}

function Import-MacVendorMap {
    $vendorPath = Resolve-MacVendorConfigPath
    $vendorMap = @{}

    if ([string]::IsNullOrWhiteSpace($vendorPath)) {
        return $vendorMap
    }

    try {
        $vendors = Import-Csv -LiteralPath $vendorPath -Delimiter ';'

        foreach ($vendor in $vendors) {
            $shortMac = ""
            $vendorName = ""

            if ($vendor.PSObject.Properties.Name -contains "shortmac") {
                $shortMac = [string]$vendor.shortmac
            }

            if ($vendor.PSObject.Properties.Name -contains "vendor") {
                $vendorName = [string]$vendor.vendor
            }

            $prefix = ($shortMac -replace '[^0-9A-Fa-f]', '').ToUpper()

            if ($prefix.Length -ge 6 -and -not [string]::IsNullOrWhiteSpace($vendorName)) {
                $vendorMap[$prefix.Substring(0, 6)] = $vendorName.Trim()
            }
        }
    }
    catch {
        throw "MAC-Vendor-Konfiguration konnte nicht gelesen werden: $vendorPath`r`n$($_.Exception.Message)"
    }

    return $vendorMap
}

function Import-RouterConfigs {
    $configDir = Resolve-RouterConfigDirectory
    if ([string]::IsNullOrWhiteSpace($configDir)) {
        return @()
    }

    $configPath = Join-Path $configDir "routers.json"
    try {
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Router-Konfiguration konnte nicht gelesen werden: $configPath`r`n$($_.Exception.Message)"
    }

    $routerItems = @()
    if ($config.PSObject.Properties.Name -contains "routers") {
        $routerItems = @($config.routers)
    }
    elseif ($config -is [array]) {
        $routerItems = @($config)
    }
    else {
        throw "Router-Konfiguration muss ein JSON-Objekt mit 'routers' oder ein JSON-Array sein: $configPath"
    }

    $routers = foreach ($router in $routerItems) {
        if (
            [string]::IsNullOrWhiteSpace($router.name) -or
            [string]::IsNullOrWhiteSpace($router.routerIp) -or
            [string]::IsNullOrWhiteSpace($router.community) -or
            [string]::IsNullOrWhiteSpace($router.oid)
        ) {
            continue
        }

        [PSCustomObject]@{
            Name      = [string]$router.name
            Subnet    = [string]$router.subnet
            Switches  = [string]$router.switches
            RouterIp  = [string]$router.routerIp
            Community = [string]$router.community
            OID       = [string]$router.oid
        }
    }

    return @($routers)
}

function Initialize-SnmpTools {
    $sourceDir = Resolve-SnmpBase64Directory
    $toolDir = Join-Path $env:LOCALAPPDATA "SnmpArpGui\bin"

    if (-not (Test-Path -LiteralPath $toolDir)) {
        New-Item -Path $toolDir -ItemType Directory -Force | Out-Null
    }

    $sourceExePath = Join-Path $sourceDir "snmpwalk.exe.b64"
    $sourceDllPath = Join-Path $sourceDir "netsnmp.dll.b64"
    $exePath = Join-Path $toolDir "snmpwalk.exe"
    $dllPath = Join-Path $toolDir "netsnmp.dll"

    Write-Base64File -Base64 (Read-Base64File -Path $sourceExePath) -Path $exePath
    Write-Base64File -Base64 (Read-Base64File -Path $sourceDllPath) -Path $dllPath

    if (-not (Test-Path -LiteralPath $exePath)) {
        throw "snmpwalk.exe konnte nicht erstellt werden: $exePath"
    }

    if (-not (Test-Path -LiteralPath $dllPath)) {
        throw "netsnmp.dll konnte nicht erstellt werden: $dllPath"
    }

    # DLL-Suchpfad fuer diesen Prozess und spaetere Child-Prozesse.
    if ($env:PATH -notlike "*$toolDir*") {
        $env:PATH = "$toolDir;$env:PATH"
    }

    return $exePath
}

function New-Label {
    param($Text, $X, $Y, $Width = 120)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, 22)
    return $label
}

function New-TextBox {
    param($X, $Y, $Width = 200, $Text = "")

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point($X, $Y)
    $textbox.Size = New-Object System.Drawing.Size($Width, 22)
    $textbox.Text = $Text
    return $textbox
}

function Convert-DataTableToObjects {
    param(
        [System.Data.DataTable]$Table
    )

    foreach ($row in $Table.Rows) {
        [PSCustomObject]@{
            IPv4        = $row.IPv4
            DNSName     = $row.DNSName
            MAC         = $row.MAC
            Vendor      = $row.Vendor
            Interface   = $row.Interface
            Description = $row.Description
            SwitchIP    = $row.SwitchIP
        }
    }
}

function Convert-DataViewToObjects {
    param(
        [System.Data.DataView]$View
    )

    foreach ($rowView in $View) {
        $row = $rowView.Row

        [PSCustomObject]@{
            IPv4        = $row.IPv4
            DNSName     = $row.DNSName
            MAC         = $row.MAC
            Vendor      = $row.Vendor
            Interface   = $row.Interface
            Description = $row.Description
            SwitchIP    = $row.SwitchIP
        }
    }
}

function ConvertTo-DataViewLikeValue {
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    $escapedValue = $Value.Replace("'", "''")
    $escapedValue = $escapedValue.Replace("[", "[[]")
    $escapedValue = $escapedValue.Replace("]", "[]]")
    $escapedValue = $escapedValue.Replace("%", "[%]")
    $escapedValue = $escapedValue.Replace("*", "[*]")

    return $escapedValue
}

try {
    $script:SnmpWalkPath = Initialize-SnmpTools
    $script:RouterConfigs = Import-RouterConfigs
    $script:MacVendorMap = Import-MacVendorMap
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Fehler beim Initialisieren",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

$script:CurrentJob = $null
if (-not $script:RouterConfigs) {
    $script:RouterConfigs = @()
}
if (-not $script:MacVendorMap) {
    $script:MacVendorMap = @{}
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "SNMP ARP Suche"
$form.Size = New-Object System.Drawing.Size(1100, 680)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(900, 560)

# Eingabefelder

$form.Controls.Add((New-Label "Router:" 20 20))
$cmbRouter = New-Object System.Windows.Forms.ComboBox
$cmbRouter.Location = New-Object System.Drawing.Point(140, 18)
$cmbRouter.Size = New-Object System.Drawing.Size(300, 22)
$cmbRouter.DropDownStyle = "DropDownList"
$form.Controls.Add($cmbRouter)

$lblRouterSubnet = New-Label "" 460 20 570
$lblRouterSubnet.AutoEllipsis = $true
$form.Controls.Add($lblRouterSubnet)

$form.Controls.Add((New-Label "IPv4 suchen:" 20 60))
$txtIpSearch = New-TextBox 140 58 180
$form.Controls.Add($txtIpSearch)

$form.Controls.Add((New-Label "MAC suchen:" 340 60))
$txtMacSearch = New-TextBox 460 58 220
$form.Controls.Add($txtMacSearch)

$form.Controls.Add((New-Label "Freitext:" 700 60 80))
$txtFreeSearch = New-TextBox 780 58 250
$form.Controls.Add($txtFreeSearch)

$chkResolveDns = New-Object System.Windows.Forms.CheckBox
$chkResolveDns.Text = "DNS aufloesen"
$chkResolveDns.Location = New-Object System.Drawing.Point(590, 101)
$chkResolveDns.Size = New-Object System.Drawing.Size(140, 22)
$chkResolveDns.Checked = $true
$form.Controls.Add($chkResolveDns)

$chkResolveVendor = New-Object System.Windows.Forms.CheckBox
$chkResolveVendor.Text = "Vendor aufloesen"
$chkResolveVendor.Location = New-Object System.Drawing.Point(735, 101)
$chkResolveVendor.Size = New-Object System.Drawing.Size(150, 22)
$chkResolveVendor.Checked = ($script:MacVendorMap.Count -gt 0)
$chkResolveVendor.Enabled = ($script:MacVendorMap.Count -gt 0)
$form.Controls.Add($chkResolveVendor)

$chkResolvePorts = New-Object System.Windows.Forms.CheckBox
$chkResolvePorts.Text = "Ports aufloesen"
$chkResolvePorts.Location = New-Object System.Drawing.Point(895, 101)
$chkResolvePorts.Size = New-Object System.Drawing.Size(140, 22)
$chkResolvePorts.Checked = $true
$form.Controls.Add($chkResolvePorts)

# Buttons

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Suche starten"
$btnStart.Location = New-Object System.Drawing.Point(20, 95)
$btnStart.Size = New-Object System.Drawing.Size(140, 32)
$form.Controls.Add($btnStart)
# Auch mit Entertaste suche starten
$form.AcceptButton = $btnStart

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Abbrechen"
$btnStop.Location = New-Object System.Drawing.Point(170, 95)
$btnStop.Size = New-Object System.Drawing.Size(110, 32)
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "CSV exportieren"
$btnExport.Location = New-Object System.Drawing.Point(290, 95)
$btnExport.Size = New-Object System.Drawing.Size(130, 32)
$form.Controls.Add($btnExport)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Auswahl kopieren"
$btnCopy.Location = New-Object System.Drawing.Point(430, 95)
$btnCopy.Size = New-Object System.Drawing.Size(140, 32)
$form.Controls.Add($btnCopy)

$form.Controls.Add((New-Label "Tabelle filtern:" 20 135))
$txtTableSearch = New-TextBox 140 133 890
$txtTableSearch.Anchor = "Top,Left,Right"
$form.Controls.Add($txtTableSearch)

# Tabelle

$table = New-Object System.Data.DataTable
[void]$table.Columns.Add("IPv4", [string])
[void]$table.Columns.Add("DNSName", [string])
[void]$table.Columns.Add("MAC", [string])
[void]$table.Columns.Add("Vendor", [string])
[void]$table.Columns.Add("Interface", [string])
[void]$table.Columns.Add("Description", [string])
[void]$table.Columns.Add("SwitchIP", [string])
$tableView = New-Object System.Data.DataView -ArgumentList $table

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(20, 165)
$grid.Size = New-Object System.Drawing.Size(1040, 415)
$grid.Anchor = "Top,Bottom,Left,Right"
$grid.AutoSizeColumnsMode = "Fill"
$grid.SelectionMode = "FullRowSelect"
$grid.MultiSelect = $true
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.DataSource = $tableView
$form.Controls.Add($grid)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Bereit. snmpwalk geladen."
$status.Location = New-Object System.Drawing.Point(20, 595)
$status.Size = New-Object System.Drawing.Size(1040, 25)
$status.Anchor = "Bottom,Left,Right"
$form.Controls.Add($status)

function Update-TableFilter {
    $searchText = $txtTableSearch.Text.Trim()
    $joinedSwitchRows = @($table.Rows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.SwitchIP) }).Count

    if ([string]::IsNullOrWhiteSpace($searchText)) {
        $tableView.RowFilter = ""
    }
    else {
        $filterText = ConvertTo-DataViewLikeValue -Value $searchText
        $tableView.RowFilter = @(
            "[IPv4] LIKE '%$filterText%'",
            "[DNSName] LIKE '%$filterText%'",
            "[MAC] LIKE '%$filterText%'",
            "[Vendor] LIKE '%$filterText%'",
            "[Interface] LIKE '%$filterText%'",
            "[Description] LIKE '%$filterText%'",
            "[SwitchIP] LIKE '%$filterText%'"
        ) -join " OR "
    }

    if ($table.Rows.Count -gt 0) {
        if ([string]::IsNullOrWhiteSpace($searchText)) {
            $status.Text = "Fertig. Gefundene Eintraege: $($table.Rows.Count). Switch-Zuordnungen: $joinedSwitchRows"
        }
        else {
            $status.Text = "Filter: $($tableView.Count) von $($table.Rows.Count) Eintraegen sichtbar. Switch-Zuordnungen: $joinedSwitchRows"
        }
    }
}

$txtTableSearch.Add_TextChanged({
    Update-TableFilter
})

foreach ($router in $script:RouterConfigs) {
    [void]$cmbRouter.Items.Add($router.Name)
}

$cmbRouter.Add_SelectedIndexChanged({
    $selectedName = [string]$cmbRouter.SelectedItem
    $selectedRouter = $script:RouterConfigs | Where-Object { $_.Name -eq $selectedName } | Select-Object -First 1

    if ($selectedRouter) {
        if ([string]::IsNullOrWhiteSpace($selectedRouter.Subnet)) {
            $lblRouterSubnet.Text = "Subnet: -"
        }
        else {
            $lblRouterSubnet.Text = "Subnet: $($selectedRouter.Subnet)"
        }

        $status.Text = "Bereit. Router: $($selectedRouter.Name)"
    }
})

if ($cmbRouter.Items.Count -gt 0) {
    $cmbRouter.SelectedIndex = 0
}

# Suche starten

$btnStart.Add_Click({
    $selectedName = [string]$cmbRouter.SelectedItem
    $selectedRouter = $script:RouterConfigs | Where-Object { $_.Name -eq $selectedName } | Select-Object -First 1

    if (-not $selectedRouter) {
        [System.Windows.Forms.MessageBox]::Show(
            "Bitte einen Router aus der Konfiguration auswaehlen.",
            "Fehlende Eingabe",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    $table.Rows.Clear()

    $btnStart.Enabled = $false
    $btnStop.Enabled = $true
    $status.Text = "SNMP- und Switch-Abfrage laufen..."

    $snmpWalkPath = $script:SnmpWalkPath
    $routerIp     = $selectedRouter.RouterIp
    $switches     = $selectedRouter.Switches
    $community    = $selectedRouter.Community
    $oid          = $selectedRouter.OID
    $ipSearch     = $txtIpSearch.Text.Trim()
    $macSearch    = $txtMacSearch.Text.Trim()
    $freeSearch   = $txtFreeSearch.Text.Trim()
    $resolveDns   = [bool]$chkResolveDns.Checked
    $resolveVendor = [bool]$chkResolveVendor.Checked
    $resolvePorts = [bool]$chkResolvePorts.Checked
    $macVendorMap = $script:MacVendorMap

    $scriptBlock = {
        param(
            $SnmpWalkPath,
            $RouterIp,
            $Switches,
            $Community,
            $Oid,
            $IpAddress,
            $MacAddress,
            $SearchString,
            $ResolveDns,
            $ResolveVendor,
            $ResolvePorts,
            $MacVendorMap
        )

        function ConvertTo-MacRegex {
            param(
                [Parameter(Mandatory = $true)]
                [string]$MacAddress
            )

            $hex = ($MacAddress -replace '[^0-9A-Fa-f]', '').ToUpper()

            if ([string]::IsNullOrWhiteSpace($hex)) {
                throw "Die angegebene MAC-Adresse enthaelt keine gueltigen Hex-Zeichen."
            }

            if ($hex -notmatch '^[0-9A-F]+$') {
                throw "Die angegebene MAC-Adresse enthaelt ungueltige Zeichen."
            }

            $chars = $hex.ToCharArray() | ForEach-Object {
                [regex]::Escape([string]$_)
            }

            return ($chars -join '[\s:\-\.]*')
        }

        function Format-MacBytes {
            param(
                [Parameter(Mandatory = $true)]
                [byte[]]$Bytes
            )

            if ($Bytes.Length -ne 6) {
                return ""
            }

            return (($Bytes | ForEach-Object { $_.ToString("X2") }) -join ' ')
        }

        function ConvertTo-NormalizedMac {
            param(
                [AllowEmptyString()]
                [string]$Mac
            )

            if ([string]::IsNullOrWhiteSpace($Mac)) {
                return ""
            }

            # Wichtig:
            # snmpwalk gibt OCTET STRINGs manchmal als Rohzeichen aus, z.B. HÛb▒õ&.
            # Das sind dann eigentlich sechs Bytes einer MAC-Adresse und kein Text.
            # Deshalb zuerst saubere Hex-Ausgaben erkennen und danach Rohzeichen zurueck in Bytes wandeln.
            # Nicht pauschal Trim() verwenden: Eine echte MAC kann als erstes Byte 09/TAB oder 20/SPACE enthalten.
            $macText = $Mac.Trim('"')
            $macTextForHex = $macText.Trim()

            # Fall 1: normale Hex-Ausgabe, z.B. C4 E7 B1 8A 11 3D,
            # C4:E7:B1:8A:11:3D oder c4e7.b18a.113d.
            if ($macTextForHex -match '^[\s0-9A-Fa-f:\-\.]+$') {
                $hex = ($macTextForHex -replace '[^0-9A-Fa-f]', '').ToUpper()

                if ($hex.Length -eq 12) {
                    return (($hex -split '(.{2})' | Where-Object { $_ }) -join ' ')
                }
            }

            # Fall 2: escaped String-Ausgabe, z.B. \304\347\261\212\021\075 oder \xC4\xE7...
            if ($macText -match '\\x[0-9A-Fa-f]{2}|\\[0-7]{3}') {
                try {
                    $byteList = New-Object 'System.Collections.Generic.List[byte]'
                    $regex = [regex]'\\x(?<hex>[0-9A-Fa-f]{2})|\\(?<oct>[0-7]{3})'

                    foreach ($m in $regex.Matches($macText)) {
                        if ($m.Groups['hex'].Success) {
                            $byteList.Add([Convert]::ToByte($m.Groups['hex'].Value, 16))
                        }
                        elseif ($m.Groups['oct'].Success) {
                            $byteList.Add([Convert]::ToByte($m.Groups['oct'].Value, 8))
                        }
                    }

                    if ($byteList.Count -eq 6) {
                        return (Format-MacBytes -Bytes $byteList.ToArray())
                    }
                }
                catch {
                    # Danach mit den anderen Methoden weiter versuchen.
                }
            }

            # Fall 3: Rohzeichen. Beispiel aus der GUI: HÛb▒õ&.
            # Unter deutschen Windows-Systemen ist das meist OEM 850. Je nach Host/PowerShell
            # kann aber auch OEM-Codepage, ANSI oder 437 beteiligt sein.
            $encodings = New-Object 'System.Collections.Generic.List[System.Text.Encoding]'

            try { $encodings.Add([Console]::OutputEncoding) } catch {}
            try { $encodings.Add([Console]::InputEncoding) } catch {}
            try { $encodings.Add([System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)) } catch {}
            try { $encodings.Add([System.Text.Encoding]::Default) } catch {}
            try { $encodings.Add([System.Text.Encoding]::GetEncoding(850)) } catch {}
            try { $encodings.Add([System.Text.Encoding]::GetEncoding(437)) } catch {}
            try { $encodings.Add([System.Text.Encoding]::GetEncoding(1252)) } catch {}

            $seen = @{}
            foreach ($encoding in $encodings) {
                if (-not $encoding) {
                    continue
                }

                $key = $encoding.WebName
                if ($seen.ContainsKey($key)) {
                    continue
                }
                $seen[$key] = $true

                try {
                    $bytes = $encoding.GetBytes($macText)

                    if ($bytes.Length -eq 6) {
                        return (Format-MacBytes -Bytes $bytes)
                    }
                }
                catch {
                    continue
                }
            }

            # Letzter Fallback: sichtbaren Wert nicht verlieren.
            return $macTextForHex
        }

        function Resolve-IPv4ToDnsName {
            param(
                [AllowEmptyString()]
                [string]$IPv4
            )

            if ([string]::IsNullOrWhiteSpace($IPv4)) {
                return ""
            }

            try {
                if (-not (Get-Command "nslookup.exe" -ErrorAction SilentlyContinue)) {
                    return ""
                }

                $lookupResult = & nslookup.exe $IPv4 2>&1

                foreach ($line in $lookupResult) {
                    $lineText = [string]$line

                    if ($lineText -match '^\s*Name:\s*(?<Name>.+?)\s*$') {
                        return $matches["Name"].Trim().TrimEnd(".")
                    }

                    if ($lineText -match 'name\s*=\s*(?<Name>.+?)\.?\s*$') {
                        return $matches["Name"].Trim().TrimEnd(".")
                    }
                }

                return ""
            }
            catch {
                return ""
            }
        }

        function Resolve-MacVendor {
            param(
                [AllowEmptyString()]
                [string]$Mac,

                [hashtable]$VendorMap
            )

            if ([string]::IsNullOrWhiteSpace($Mac) -or -not $VendorMap -or $VendorMap.Count -eq 0) {
                return ""
            }

            $hex = ($Mac -replace '[^0-9A-Fa-f]', '').ToUpper()

            if ($hex.Length -lt 6) {
                return ""
            }

            $prefix = $hex.Substring(0, 6)

            if ($VendorMap.ContainsKey($prefix)) {
                return [string]$VendorMap[$prefix]
            }

            return ""
        }

        function ConvertTo-CanonicalMacKey {
            param(
                [AllowEmptyString()]
                [string]$Mac
            )

            if ([string]::IsNullOrWhiteSpace($Mac)) {
                return ""
            }

            $hex = ($Mac -replace '[^0-9A-Fa-f]', '').ToUpper()
            if ($hex.Length -ne 12) {
                return ""
            }

            return $hex
        }

        function ConvertTo-UInt32IPv4 {
            param(
                [Parameter(Mandatory = $true)]
                [string]$IPAddress
            )

            $bytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()

            if ($bytes.Count -ne 4) {
                throw "Nur IPv4 wird unterstuetzt: $IPAddress"
            }

            [array]::Reverse($bytes)
            return [BitConverter]::ToUInt32($bytes, 0)
        }

        function ConvertFrom-UInt32IPv4 {
            param(
                [Parameter(Mandatory = $true)]
                [uint32]$IPAddressInt
            )

            $bytes = [BitConverter]::GetBytes($IPAddressInt)
            [array]::Reverse($bytes)
            return ([System.Net.IPAddress]::new($bytes)).ToString()
        }

        function Get-IPv4RangeFromCidr {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Cidr
            )

            if ($Cidr -notmatch '^(?<IP>\d{1,3}(?:\.\d{1,3}){3})/(?<Prefix>\d{1,2})$') {
                throw "Ungueltiges CIDR-Format. Beispiel: 192.168.0.1/24"
            }

            $ip = $matches['IP']
            $prefix = [int]$matches['Prefix']

            if ($prefix -lt 0 -or $prefix -gt 32) {
                throw "Ungueltige CIDR-Prefixlaenge: $prefix"
            }

            $ipInt = ConvertTo-UInt32IPv4 -IPAddress $ip
            $mask = [uint32]0

            for ($i = 0; $i -lt $prefix; $i++) {
                $mask = $mask -bor ([uint32]1 -shl (31 - $i))
            }

            $network = [uint32]($ipInt -band $mask)
            $wildcard = [uint32]([uint32]::MaxValue -bxor $mask)
            $broadcast = [uint32]($network -bor $wildcard)

            if ($prefix -le 30) {
                $start = [uint32]($network + 1)
                $end = [uint32]($broadcast - 1)
            }
            else {
                $start = $network
                $end = $broadcast
            }

            for ($current = $start; $current -le $end; $current++) {
                ConvertFrom-UInt32IPv4 -IPAddressInt $current
            }
        }

        function Test-IPv4Ping {
            param(
                [Parameter(Mandatory = $true)]
                [string]$IPAddress,

                [int]$TimeoutMilliseconds = 500
            )

            try {
                $ping = New-Object System.Net.NetworkInformation.Ping
                $reply = $ping.Send($IPAddress, $TimeoutMilliseconds)
                return ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
            }
            catch {
                return $false
            }
            finally {
                if ($ping) {
                    $ping.Dispose()
                }
            }
        }

        function Test-SwitchOnline {
            param(
                [Parameter(Mandatory = $true)]
                [string]$IPAddress,

                [int]$TimeoutMilliseconds = 1000,

                [int]$Attempts = 2
            )

            for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
                try {
                    if (Test-IPv4Ping -IPAddress $IPAddress -TimeoutMilliseconds $TimeoutMilliseconds) {
                        return $true
                    }
                }
                catch {
                    # Danach mit dem naechsten Versuch weitermachen.
                }

                if ($attempt -lt $Attempts) {
                    Start-Sleep -Milliseconds 150
                }
            }

            return $false
        }

        function ConvertFrom-SnmpWalkLine {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Line
            )

            if ($Line -match '^(?<Oid>\.?[0-9]+(?:\.[0-9]+)*)\s+=\s+(?<SnmpType>[^:]+):\s*(?<Value>.*)$') {
                $value = $matches['Value'].Trim()

                if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
                    $value = $value.Substring(1, $value.Length - 2)
                }

                [PSCustomObject]@{
                    Oid      = $matches['Oid'].TrimStart('.')
                    SnmpType = $matches['SnmpType'].Trim()
                    Value    = $value
                    RawLine  = $Line
                }
            }
        }

        function Get-SnmpIndexPart {
            param(
                [Parameter(Mandatory = $true)]
                [string]$FullOid,

                [Parameter(Mandatory = $true)]
                [string]$BaseOid
            )

            $FullOid = $FullOid.TrimStart('.')
            $BaseOid = $BaseOid.TrimStart('.')

            if ($FullOid -match "^$([regex]::Escape($BaseOid))\.(?<Index>.+)$") {
                return $matches['Index']
            }

            return $null
        }

        function Convert-MacFromDecimalBytes {
            param(
                [Parameter(Mandatory = $true)]
                [string[]]$MacBytes
            )

            if ($MacBytes.Count -ne 6) {
                throw "MAC hat nicht exakt 6 Bytes."
            }

            ($MacBytes | ForEach-Object {
                $byte = [int]$_

                if ($byte -lt 0 -or $byte -gt 255) {
                    throw "Ungueltiges MAC-Byte: $byte"
                }

                "{0:X2}" -f $byte
            }) -join ' '
        }

        function Invoke-SnmpWalkForSwitch {
            param(
                [Parameter(Mandatory = $true)]
                [string]$SwitchIP,

                [Parameter(Mandatory = $true)]
                [string]$Oid,

                [Parameter(Mandatory = $true)]
                [string]$Community,

                [Parameter(Mandatory = $true)]
                [string]$SnmpWalkPath
            )

            $env:MIBS = ""

            $output = & $SnmpWalkPath -v2c -c $Community -On -t 1 -r 0 $SwitchIP $Oid 2>&1
            $lines = @($output | ForEach-Object { [string]$_ })
            $text = ($lines -join " ")

            if ($LASTEXITCODE -ne 0 -or
                $text -match 'Timeout:\s+No Response|No Such Object|No Such Instance|Unknown Object Identifier|Authentication failure|authorizationError|not in view') {
                throw $text
            }

            return $lines
        }

        function Get-CiscoSwitchPortSecurity {
            param(
                [Parameter(Mandatory = $true)]
                [string]$SwitchIP,

                [Parameter(Mandatory = $true)]
                [string]$Community,

                [Parameter(Mandatory = $true)]
                [string]$SnmpWalkPath
            )

            $oidIfName = "1.3.6.1.2.1.31.1.1.1.1"
            $oidIfAlias = "1.3.6.1.2.1.31.1.1.1.18"
            $oidIfDescr = "1.3.6.1.2.1.2.2.1.2"
            $oidSecureVlan = "1.3.6.1.4.1.9.9.315.1.2.3.1.3"
            $oidSecureFallback = "1.3.6.1.4.1.9.9.315.1.2.2.1.2"

            $ifNames = @{}
            $ifAliases = @{}

            try {
                $ifLines = Invoke-SnmpWalkForSwitch -SwitchIP $SwitchIP -Oid $oidIfName -Community $Community -SnmpWalkPath $SnmpWalkPath

                foreach ($item in ($ifLines | ForEach-Object { ConvertFrom-SnmpWalkLine -Line $_ })) {
                    if (-not $item) {
                        continue
                    }

                    $ifIndex = Get-SnmpIndexPart -FullOid $item.Oid -BaseOid $oidIfName
                    if ($ifIndex -and $ifIndex -match '^\d+$') {
                        $ifNames[$ifIndex] = $item.Value
                    }
                }
            }
            catch {
                try {
                    $ifDescrLines = Invoke-SnmpWalkForSwitch -SwitchIP $SwitchIP -Oid $oidIfDescr -Community $Community -SnmpWalkPath $SnmpWalkPath

                    foreach ($item in ($ifDescrLines | ForEach-Object { ConvertFrom-SnmpWalkLine -Line $_ })) {
                        if (-not $item) {
                            continue
                        }

                        $ifIndex = Get-SnmpIndexPart -FullOid $item.Oid -BaseOid $oidIfDescr
                        if ($ifIndex -and $ifIndex -match '^\d+$') {
                            $ifNames[$ifIndex] = $item.Value
                        }
                    }
                }
                catch {
                    return @()
                }
            }

            try {
                $ifAliasLines = Invoke-SnmpWalkForSwitch -SwitchIP $SwitchIP -Oid $oidIfAlias -Community $Community -SnmpWalkPath $SnmpWalkPath

                foreach ($item in ($ifAliasLines | ForEach-Object { ConvertFrom-SnmpWalkLine -Line $_ })) {
                    if (-not $item) {
                        continue
                    }

                    $ifIndex = Get-SnmpIndexPart -FullOid $item.Oid -BaseOid $oidIfAlias
                    if ($ifIndex -and $ifIndex -match '^\d+$') {
                        $ifAliases[$ifIndex] = $item.Value
                    }
                }
            }
            catch {
                $ifAliases = @{}
            }

            $results = New-Object 'System.Collections.Generic.List[object]'

            foreach ($tableDefinition in @(
                @{ Oid = $oidSecureVlan; HasVlan = $true },
                @{ Oid = $oidSecureFallback; HasVlan = $false }
            )) {
                try {
                    $secureLines = Invoke-SnmpWalkForSwitch -SwitchIP $SwitchIP -Oid $tableDefinition.Oid -Community $Community -SnmpWalkPath $SnmpWalkPath

                    foreach ($item in ($secureLines | ForEach-Object { ConvertFrom-SnmpWalkLine -Line $_ })) {
                        if (-not $item) {
                            continue
                        }

                        $indexPart = Get-SnmpIndexPart -FullOid $item.Oid -BaseOid $tableDefinition.Oid
                        if (-not $indexPart) {
                            continue
                        }

                        $parts = $indexPart -split '\.'
                        $expectedCount = if ($tableDefinition.HasVlan) { 8 } else { 7 }

                        if ($parts.Count -ne $expectedCount) {
                            continue
                        }

                        $ifIndex = $parts[0]
                        $macPart = $parts[1..6]

                        try {
                            $mac = Convert-MacFromDecimalBytes -MacBytes $macPart
                        }
                        catch {
                            continue
                        }

                        $interface = if ($ifNames.ContainsKey($ifIndex)) {
                            $ifNames[$ifIndex]
                        }
                        else {
                            "<IfIndex $ifIndex>"
                        }

                        $description = if ($ifAliases.ContainsKey($ifIndex)) {
                            $ifAliases[$ifIndex]
                        }
                        else {
                            ""
                        }

                        $results.Add([PSCustomObject]@{
                            SwitchIP    = $SwitchIP
                            Interface   = $interface
                            Description = $description
                            MAC         = $mac
                        })
                    }

                    if ($results.Count -gt 0) {
                        break
                    }
                }
                catch {
                    continue
                }
            }

            return $results.ToArray()
        }

        function Invoke-CiscoPortSecurityNetworkScan {
            param(
                [AllowEmptyString()]
                [string]$NetworkCidr,

                [int]$ThrottleLimit = 32
            )

            if ([string]::IsNullOrWhiteSpace($NetworkCidr)) {
                return @()
            }

            $addresses = @(Get-IPv4RangeFromCidr -Cidr $NetworkCidr)
            $results = New-Object 'System.Collections.Generic.List[object]'
            $functionDefinitions = @(
                ${function:Test-IPv4Ping}.Ast.Extent.Text
                ${function:Test-SwitchOnline}.Ast.Extent.Text
                ${function:ConvertFrom-SnmpWalkLine}.Ast.Extent.Text
                ${function:Get-SnmpIndexPart}.Ast.Extent.Text
                ${function:Convert-MacFromDecimalBytes}.Ast.Extent.Text
                ${function:Invoke-SnmpWalkForSwitch}.Ast.Extent.Text
                ${function:Get-CiscoSwitchPortSecurity}.Ast.Extent.Text
            ) -join "`r`n"

            $scanScript = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$SwitchIP,

                    [Parameter(Mandatory = $true)]
                    [string]$CommunityValue,

                    [Parameter(Mandatory = $true)]
                    [string]$SnmpWalkPathValue,

                    [Parameter(Mandatory = $true)]
                    [string]$FunctionDefinitions,

                    [int]$PingTimeoutMilliseconds = 1000,

                    [bool]$UseOnlineCheck = $true
                )

                $snmpToolDir = Split-Path -Parent $SnmpWalkPathValue
                if (-not [string]::IsNullOrWhiteSpace($snmpToolDir) -and $env:PATH -notlike "*$snmpToolDir*") {
                    $env:PATH = "$snmpToolDir;$env:PATH"
                }

                Invoke-Expression $FunctionDefinitions

                if ($UseOnlineCheck -and -not (Test-SwitchOnline -IPAddress $SwitchIP -TimeoutMilliseconds $PingTimeoutMilliseconds)) {
                    return @()
                }

                return @(Get-CiscoSwitchPortSecurity -SwitchIP $SwitchIP -Community $CommunityValue -SnmpWalkPath $SnmpWalkPathValue)
            }

            function Invoke-PortSecurityRunspacePass {
                param(
                    [bool]$UseOnlineCheck
                )

                $passResults = New-Object 'System.Collections.Generic.List[object]'
                $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit)
                $runspacePool.Open()
                $tasks = New-Object 'System.Collections.Generic.List[object]'

                try {
                    foreach ($switchIp in $addresses) {
                        $powerShell = [powershell]::Create()
                        $powerShell.RunspacePool = $runspacePool

                        [void]$powerShell.AddScript($scanScript.ToString())
                        [void]$powerShell.AddArgument($switchIp)
                        [void]$powerShell.AddArgument($Community)
                        [void]$powerShell.AddArgument($SnmpWalkPath)
                        [void]$powerShell.AddArgument($functionDefinitions)
                        [void]$powerShell.AddArgument(1000)
                        [void]$powerShell.AddArgument($UseOnlineCheck)

                        $tasks.Add([PSCustomObject]@{
                            PowerShell = $powerShell
                            Handle     = $powerShell.BeginInvoke()
                        })
                    }

                    foreach ($task in $tasks) {
                        try {
                            foreach ($entry in @($task.PowerShell.EndInvoke($task.Handle))) {
                                if ($entry) {
                                    $passResults.Add($entry)
                                }
                            }
                        }
                        catch {
                            continue
                        }
                    }
                }
                finally {
                    foreach ($task in $tasks) {
                        if ($task.PowerShell) {
                            $task.PowerShell.Dispose()
                        }
                    }

                    if ($runspacePool) {
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                }

                return $passResults.ToArray()
            }

            foreach ($entry in @(Invoke-PortSecurityRunspacePass -UseOnlineCheck $true)) {
                $results.Add($entry)
            }

            if ($results.Count -eq 0) {
                foreach ($entry in @(Invoke-PortSecurityRunspacePass -UseOnlineCheck $false)) {
                    $results.Add($entry)
                }
            }

            return $results.ToArray()
        }

        function ConvertFrom-SnmpWalkArpLine {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Line
            )

            # Beispiel:
            # .1.3.6.1.2.1.3.1.1.2.193.1.192.168.100.23 = Hex-STRING: C4 E7 B1 8A 11 3D

            $pattern = '^(?<Oid>\.[0-9.]+)\s*=\s*(?<Type>[^:]+):(?<Value>.*)$'

            if ($Line -notmatch $pattern) {
                return $null
            }

            $fullOid = $matches['Oid'].Trim()
            $type    = $matches['Type'].Trim()

            # Den Wert nicht pauschal mit Trim() behandeln, weil eine MAC-Adresse
            # als Roh-OCTET-STRING auch mit Tab/Leerzeichen beginnen koennte.
            $value = $matches['Value']
            if ($value.StartsWith(' ')) {
                $value = $value.Substring(1)
            }
            $value = $value.Trim('"')

            $oidParts = $fullOid.TrimStart('.') -split '\.'

            $ipv4 = $null

            if ($oidParts.Count -ge 4) {
                $lastFour = $oidParts[-4..-1]

                $validIpParts = $true

                foreach ($part in $lastFour) {
                    if ($part -notmatch '^\d+$') {
                        $validIpParts = $false
                        break
                    }

                    if ([int]$part -lt 0 -or [int]$part -gt 255) {
                        $validIpParts = $false
                        break
                    }
                }

                if ($validIpParts) {
                    $ipv4 = $lastFour -join '.'
                }
            }

            if ([string]::IsNullOrWhiteSpace($value)) {
                $mac = ""
            }
            else {
                $mac = ConvertTo-NormalizedMac -Mac $value
            }

            [PSCustomObject]@{
                OID          = $fullOid
                IPv4         = $ipv4
                DNSName      = ""
                MAC          = $mac
                Vendor       = ""
                SNMPType     = $type
                OriginalLine = $Line
            }
        }

        if (-not (Test-Path -LiteralPath $SnmpWalkPath)) {
            throw "snmpwalk.exe wurde nicht gefunden: $SnmpWalkPath"
        }

        $toolDir = Split-Path -Parent $SnmpWalkPath
        if ($env:PATH -notlike "*$toolDir*") {
            $env:PATH = "$toolDir;$env:PATH"
        }

        $macRegex = $null

        if (-not [string]::IsNullOrWhiteSpace($MacAddress)) {
            $macRegex = ConvertTo-MacRegex -MacAddress $MacAddress
        }

        # -Onx: numerische OIDs und String-/OCTET-Werte moeglichst als Hex ausgeben.
        # Das verhindert Zeichensalat bei MAC-Adressen wie HÛb▒õ&.
        $walkResult = & $SnmpWalkPath -v2c -c $Community -Onx $RouterIp $Oid 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "snmpwalk.exe wurde mit Exitcode $LASTEXITCODE beendet.`r`n$($walkResult | Out-String)"
        }

        $dnsCache = @{}

        $items = foreach ($line in $walkResult) {
            $lineText = [string]$line
            $entry = ConvertFrom-SnmpWalkArpLine -Line $lineText

            if (-not $entry) {
                continue
            }

            $match = $true

            if (-not [string]::IsNullOrWhiteSpace($IpAddress)) {
                if ($entry.IPv4 -ne $IpAddress) {
                    $match = $false
                }
            }

            if ($match -and $macRegex) {
                if (($entry.MAC -notmatch $macRegex) -and ($entry.OriginalLine -notmatch $macRegex)) {
                    $match = $false
                }
            }

            if ($match -and -not [string]::IsNullOrWhiteSpace($SearchString)) {
                $escapedSearch = [regex]::Escape($SearchString)

                if ($entry.OriginalLine -notmatch $escapedSearch) {
                    $match = $false
                }
            }

            if ($match) {
                if ($ResolveDns -and -not [string]::IsNullOrWhiteSpace($entry.IPv4)) {
                    if ($dnsCache.ContainsKey($entry.IPv4)) {
                        $entry.DNSName = $dnsCache[$entry.IPv4]
                    }
                    else {
                        $dnsName = Resolve-IPv4ToDnsName -IPv4 $entry.IPv4
                        $dnsCache[$entry.IPv4] = $dnsName
                        $entry.DNSName = $dnsName
                    }
                }

                if ($ResolveVendor) {
                    $entry.Vendor = Resolve-MacVendor -Mac $entry.MAC -VendorMap $MacVendorMap
                }

                [PSCustomObject]@{
                    IPv4        = $entry.IPv4
                    DNSName     = $entry.DNSName
                    MAC         = $entry.MAC
                    Vendor      = $entry.Vendor
                    Interface   = ""
                    Description = ""
                    SwitchIP    = ""
                }
            }
        }

        $portSecurityLookup = @{}

        if ($ResolvePorts) {
            try {
                foreach ($portEntry in (Invoke-CiscoPortSecurityNetworkScan -NetworkCidr $Switches)) {
                    $macKey = ConvertTo-CanonicalMacKey -Mac $portEntry.MAC

                    if ([string]::IsNullOrWhiteSpace($macKey)) {
                        continue
                    }

                    if (-not $portSecurityLookup.ContainsKey($macKey)) {
                        $portSecurityLookup[$macKey] = $portEntry
                    }
                }
            }
            catch {
                $portSecurityLookup = @{}
            }
        }

        foreach ($item in $items) {
            $macKey = ConvertTo-CanonicalMacKey -Mac $item.MAC

            if (-not [string]::IsNullOrWhiteSpace($macKey) -and $portSecurityLookup.ContainsKey($macKey)) {
                $portEntry = $portSecurityLookup[$macKey]
                $item.Interface = $portEntry.Interface
                $item.Description = $portEntry.Description
                $item.SwitchIP = $portEntry.SwitchIP
            }
        }

        return $items
    }

    try {
        $script:CurrentJob = Start-Job -ScriptBlock $scriptBlock -ArgumentList @(
            $snmpWalkPath,
            $routerIp,
            $switches,
            $community,
            $oid,
            $ipSearch,
            $macSearch,
            $freeSearch,
            $resolveDns,
            $resolveVendor,
            $resolvePorts,
            $macVendorMap
        )
    }
    catch {
        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        $status.Text = "Fehler beim Starten der Suche."
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fehler", "OK", "Error") | Out-Null
    }
})

# Abbrechen

$btnStop.Add_Click({
    if ($script:CurrentJob) {
        Stop-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
        Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
        $script:CurrentJob = $null

        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        $status.Text = "Suche abgebrochen."
    }
})

# Job regelmaessig pruefen

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

$timer.Add_Tick({
    if (-not $script:CurrentJob) {
        return
    }

    if ($script:CurrentJob.State -in @("Completed", "Failed", "Stopped")) {
        try {
            if ($script:CurrentJob.State -eq "Completed") {
                $results = Receive-Job -Job $script:CurrentJob -ErrorAction Stop

                foreach ($entry in $results) {
                    $row = $table.NewRow()
                    $row.IPv4    = $entry.IPv4
                    $row.DNSName = $entry.DNSName
                    $row.MAC     = $entry.MAC
                    $row.Vendor  = $entry.Vendor
                    $row.Interface = $entry.Interface
                    $row.Description = $entry.Description
                    $row.SwitchIP = $entry.SwitchIP
                    $table.Rows.Add($row)
                }

                Update-TableFilter
            }
            elseif ($script:CurrentJob.State -eq "Failed") {
                $err = Receive-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue 2>&1
                $status.Text = "Fehler bei der SNMP-Abfrage."
                [System.Windows.Forms.MessageBox]::Show(
                    ($err | Out-String),
                    "Fehler",
                    "OK",
                    "Error"
                ) | Out-Null
            }
            else {
                $status.Text = "Suche abgebrochen."
            }
        }
        catch {
            $status.Text = "Fehler beim Auswerten der Ergebnisse."
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fehler", "OK", "Error") | Out-Null
        }
        finally {
            Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
            $script:CurrentJob = $null

            $btnStart.Enabled = $true
            $btnStop.Enabled = $false
        }
    }
})

$timer.Start()

# CSV exportieren

$btnExport.Add_Click({
    if ($tableView.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Es sind keine sichtbaren Ergebnisse vorhanden.",
            "CSV Export",
            "OK",
            "Information"
        ) | Out-Null
        return
    }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "CSV Datei|*.csv"
    $dialog.FileName = "snmp-arp.csv"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            Convert-DataViewToObjects -View $tableView |
                Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ";"

            $status.Text = "CSV exportiert: $($dialog.FileName)"
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Export-Fehler", "OK", "Error") | Out-Null
        }
    }
})

# Auswahl kopieren

$btnCopy.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Bitte mindestens eine Zeile auswaehlen.",
            "Kopieren",
            "OK",
            "Information"
        ) | Out-Null
        return
    }

    $lines = @()
    $lines += "IPv4`tDNSName`tMAC`tVendor`tInterface`tDescription`tSwitchIP"

    foreach ($row in $grid.SelectedRows) {
        if ($row.IsNewRow) {
            continue
        }

        $lines += "$($row.Cells["IPv4"].Value)`t$($row.Cells["DNSName"].Value)`t$($row.Cells["MAC"].Value)`t$($row.Cells["Vendor"].Value)`t$($row.Cells["Interface"].Value)`t$($row.Cells["Description"].Value)`t$($row.Cells["SwitchIP"].Value)"
    }

    [System.Windows.Forms.Clipboard]::SetText(($lines -join [Environment]::NewLine))
    $status.Text = "Auswahl wurde in die Zwischenablage kopiert."
})

$form.Add_FormClosing({
    if ($script:CurrentJob) {
        Stop-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
        Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
    }
})

[void]$form.ShowDialog()
