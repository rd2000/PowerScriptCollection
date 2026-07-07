<#
    Create-MACVendors-CSV.ps1

    [ #1 Part of text ]

    ------------------------------------------------
    00-90-88   (hex)		BAXALL SECURITY LTD.
    009088     (base 16)    BAXALL SECURITY LTD.
                    UNIT 1 CASTLEHILL
                    STOCKPORT  Great Britain SK6 2SV  
                    GB
    ------------------------------------------------

    [ #2 Extract line from text ]

    009088     (base 16)		BAXALL SECURITY LTD.

    [ #3 And convert line to PSObject ]

    @{
        shortmac = 009088
        vendor = BAXALL SECURITY LTD.
    }    
#>

function Convert-OuiLinesToObject {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    foreach ($line in $Lines) {

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $col = $line -split '\s+\(base 16\)\s+', 2

        if ($col.Count -lt 2) {
            continue
        }

        [PSCustomObject]@{
            ShortMac = $col[0].Trim().ToLowerInvariant()
            Vendor   = $col[1].Trim()
        }
    }
}

# To reduce datadownloads, while develop we download file max one time
if (!$MACAddressVendors) {
    $MACAddressVendors = Invoke-WebRequest -uri 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
}

# Get lines which contains string: (base16) 
$lines = $MACAddressVendors.content.Split([Environment]::NewLine) | Select-String '(base 16)'

$result = Convert-OuiLinesToObject -Lines $lines

$toolsDirectory = Split-Path -Parent $PSCommandPath
$configDirectory = Join-Path $toolsDirectory 'config'
$outputPath = Join-Path $configDirectory 'macvendors.csv'

if (!(Test-Path -Path $configDirectory -PathType Container)) {
    New-Item -Path $configDirectory -ItemType Directory -Force | Out-Null
}

$result | Export-Csv -Delimiter ';' $outputPath