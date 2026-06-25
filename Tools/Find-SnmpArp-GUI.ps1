# Find-SnmpArp-GUI.ps1
# GUI fuer SNMP-ARP-Suche mit ausgelagerten Net-SNMP-Base64-Dateien
# Ausgabe: IPv4, DNSName, MAC

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

    foreach ($path in @($PSScriptRoot, $PSCommandPath, [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)) {
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
            IPv4    = $row.IPv4
            DNSName = $row.DNSName
            MAC     = $row.MAC
        }
    }
}

try {
    $script:SnmpWalkPath = Initialize-SnmpTools
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Fehler beim Initialisieren von snmpwalk",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

$script:CurrentJob = $null

$form = New-Object System.Windows.Forms.Form
$form.Text = "SNMP ARP Suche"
$form.Size = New-Object System.Drawing.Size(1100, 680)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(900, 560)

# Eingabefelder

$form.Controls.Add((New-Label "Router-IP:" 20 20))
$txtRouterIp = New-TextBox 140 18 180 "routername"
$form.Controls.Add($txtRouterIp)

$form.Controls.Add((New-Label "Community:" 340 20))
$txtCommunity = New-TextBox 460 18 120 "public"
$form.Controls.Add($txtCommunity)

$form.Controls.Add((New-Label "OID:" 600 20 50))
$txtOid = New-TextBox 650 18 380 ".1.3.6.1.2.1.3.1.1.2"
$form.Controls.Add($txtOid)

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

# Tabelle

$table = New-Object System.Data.DataTable
[void]$table.Columns.Add("IPv4", [string])
[void]$table.Columns.Add("DNSName", [string])
[void]$table.Columns.Add("MAC", [string])

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(20, 140)
$grid.Size = New-Object System.Drawing.Size(1040, 440)
$grid.Anchor = "Top,Bottom,Left,Right"
$grid.AutoSizeColumnsMode = "Fill"
$grid.SelectionMode = "FullRowSelect"
$grid.MultiSelect = $true
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.DataSource = $table
$form.Controls.Add($grid)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Bereit. snmpwalk geladen."
$status.Location = New-Object System.Drawing.Point(20, 595)
$status.Size = New-Object System.Drawing.Size(1040, 25)
$status.Anchor = "Bottom,Left,Right"
$form.Controls.Add($status)

# Suche starten

$btnStart.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtRouterIp.Text)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Bitte eine Router-IP oder einen Routernamen eingeben.",
            "Fehlende Eingabe",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    $table.Rows.Clear()

    $btnStart.Enabled = $false
    $btnStop.Enabled = $true
    $status.Text = "SNMP-Abfrage laeuft..."

    $snmpWalkPath = $script:SnmpWalkPath
    $routerIp     = $txtRouterIp.Text.Trim()
    $community    = $txtCommunity.Text.Trim()
    $oid          = $txtOid.Text.Trim()
    $ipSearch     = $txtIpSearch.Text.Trim()
    $macSearch    = $txtMacSearch.Text.Trim()
    $freeSearch   = $txtFreeSearch.Text.Trim()
    $resolveDns   = [bool]$chkResolveDns.Checked

    $scriptBlock = {
        param(
            $SnmpWalkPath,
            $RouterIp,
            $Community,
            $Oid,
            $IpAddress,
            $MacAddress,
            $SearchString,
            $ResolveDns
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

                [PSCustomObject]@{
                    IPv4    = $entry.IPv4
                    DNSName = $entry.DNSName
                    MAC     = $entry.MAC
                }
            }
        }

        return $items
    }

    try {
        $script:CurrentJob = Start-Job -ScriptBlock $scriptBlock -ArgumentList @(
            $snmpWalkPath,
            $routerIp,
            $community,
            $oid,
            $ipSearch,
            $macSearch,
            $freeSearch,
            $resolveDns
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
                    $table.Rows.Add($row)
                }

                $status.Text = "Fertig. Gefundene Eintraege: $($table.Rows.Count)"
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
    if ($table.Rows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Es sind keine Ergebnisse vorhanden.",
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
            Convert-DataTableToObjects -Table $table |
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
    $lines += "IPv4`tDNSName`tMAC"

    foreach ($row in $grid.SelectedRows) {
        if ($row.IsNewRow) {
            continue
        }

        $lines += "$($row.Cells["IPv4"].Value)`t$($row.Cells["DNSName"].Value)`t$($row.Cells["MAC"].Value)"
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
