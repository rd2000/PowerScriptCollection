<#
    Create-MACVendors-CSV.ps1

    [ #1 Part of text ]

    ------------------------------------------------
    00-90-88   (hex)		BAXALL SECURITY LTD.
    009088     (base 16)		BAXALL SECURITY LTD.
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


# To reduce datadownloads, while develop we download file max one time
if (!$MACAddressVendors) {
    $MACAddressVendors = Invoke-WebRequest -uri 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
}


# Get lines which contains string: (base16) 
$lines = $MACAddressVendors.content.Split([Environment]::NewLine) | Select-String '(base 16)'


# Convert to PSObject
$jobobject = @()
foreach ($line in $lines) {
    
    $col = $line -split '\(base 16\)'

    $hash = New-Object PSObject -property @{
        shortmac = $col[0].Trim().ToLower()
        vendor = $col[1].Trim()
    }
    
    $jobobject += $hash
} 

#$jobobject
$toolsDirectory = Split-Path -Parent $PSCommandPath
$configDirectory = Join-Path $toolsDirectory 'config'
$outputPath = Join-Path $configDirectory 'macvendors.csv'

if (!(Test-Path -Path $configDirectory -PathType Container)) {
    New-Item -Path $configDirectory -ItemType Directory -Force | Out-Null
}

$jobobject | Export-Csv -Delimiter ';' $outputPath

