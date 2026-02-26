<# TEST #>

$functionFile = Join-Path (Join-Path $PSScriptRoot "..\functions") "ConvertFrom-TextTable.ps1"
. $functionFile

Write-Host "This is a test for function: ConvertFrom-TextTable.ps1" -ForegroundColor Blue

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message`nExpected: '$Expected'`nActual:   '$Actual'"
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$textTable = @"
+-----------+-----------+-------+----------------+-------------------+
| Vorname   | Nachname  | PLZ   | Ort            | Straße            |
+-----------+-----------+-------+----------------+-------------------+
| John      | Meier     | 10115 | Berlin         | Hauptstraße 12    |
| Lisa      | Schmidt   | 80331 | München        | Bahnhofstraße 8   |
| Michael   | Müller    | 20095 | Hamburg        | Lindenweg 3       |
+-----------+-----------+-------+----------------+-------------------+
"@

$jsonString = @"
{
    "tableaddresses": {
        "removelines": {
            "header": 3,
            "footer": 1
        },
        "extract": {
            "Vorname": { "start": 3, "length": 10 },
            "Nachname": { "start": 14, "length": 10 },
            "PLZ": { "start": 26, "length": 6 },
            "Ort": { "start": 34, "length": 15 },
            "Straße": { "start": 52, "length": 17 }
        }
    }
}
"@

try {
    $result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString -mapName "tableaddresses"

    Assert-Equal -Actual $result.Count -Expected 3 -Message "Unexpected number of parsed rows."
    Assert-Equal -Actual ($result[0].Vorname) -Expected "John" -Message "Row 1 Vorname mismatch."
    Assert-Equal -Actual ($result[0].Nachname) -Expected "Meier" -Message "Row 1 Nachname mismatch."
    Assert-Equal -Actual ($result[0].PLZ) -Expected "10115" -Message "Row 1 PLZ mismatch."
    Assert-Equal -Actual ($result[1].Ort) -Expected "München" -Message "Row 2 Ort mismatch."
    Assert-Equal -Actual ($result[2].Straße) -Expected "Lindenweg 3" -Message "Row 3 Straße mismatch."

    $propertyNames = $result[0].PSObject.Properties.Name
    Assert-True -Condition ($propertyNames -contains "Vorname") -Message "Expected property 'Vorname' missing."
    Assert-True -Condition ($propertyNames -contains "Nachname") -Message "Expected property 'Nachname' missing."
    Assert-True -Condition ($propertyNames -contains "PLZ") -Message "Expected property 'PLZ' missing."
    Assert-True -Condition ($propertyNames -contains "Ort") -Message "Expected property 'Ort' missing."
    Assert-True -Condition ($propertyNames -contains "Straße") -Message "Expected property 'Straße' missing."

    Write-Host "Test passed :-)" -ForegroundColor Green
}
catch {
    Write-Error "Test failed :-("
    Write-Error $_
}
