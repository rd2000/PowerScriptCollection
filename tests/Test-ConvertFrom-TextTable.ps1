<# TEST - Do not change the test, please! #>

$IncPath = "..\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"
.$IncPath"Get-CustomHash.ps1"

# Example data (The table as string)
# MD5 hash: 8C1F1B89221E7FE2B827FB7AC8BC4D3D
$textTable = @"
+-----------+-----------+-------+----------------+-------------------+
| Vorname   | Nachname  | PLZ   | Ort            | Straße            |
+-----------+-----------+-------+----------------+-------------------+
| John      | Meier     | 10115 | Berlin         | Hauptstraße 12    |
| Lisa      | Schmidt   | 80331 | München        | Bahnhofstraße 8   |
| Michael   | Müller    | 20095 | Hamburg        | Lindenweg 3       |
| Sarah     | Weber     | 50667 | Köln           | Gartenstraße 22   |
| David     | Schneider | 01067 | Dresden        | Parkallee 7       |
| Laura     | Fischer   | 70173 | Stuttgart      | Schulstraße 19    |
| Markus    | Wolf      | 28195 | Bremen         | Rosenweg 4        |
| Anna      | Krause    | 55116 | Mainz          | Brunnenstraße 15  |
| Peter     | Bauer     | 90403 | Nürnberg       | Kirchplatz 2      |
| Julia     | Zimmermann| 14467 | Potsdam        | Alte Allee 10     |
+-----------+-----------+-------+----------------+-------------------+
"@


# JSON definition as string
# MD5 hash: 8DF69827B0B34FF4CD0390A0A9B5467A
$jsonString = @"
{
    "tableaddresses": {
        "removelines": {
            "header": 3,
            "footer": 1
        },
        "extract": {
            "Vorname": { "start": 2, "length": 10 },
            "Nachname": { "start": 14, "length": 10 },
            "PLZ": { "start": 26, "length": 6 },
            "Ort": { "start": 34, "length": 15 },
            "Straße": { "start": 51, "length": 18 }
        }
    }
}
"@

# The test intro
Write-Host "This is a test for function: Get-CustomHash.ps1" -ForegroundColor Blue

# First: Check, if the function has been changed since the last test
if ((Get-FileHash -Path ".\functions\ConvertFrom-TextTable.ps1" -Algorithm 'MD5').Hash -ne "92299882A8A6D186C63D816AF8BFC686") {
    Write-Warning "Function has been modified since the last test!"
    Write-Host "If test passed, please adjust the checksum of the function to disable this warning."
}

# Run function
try {

    $result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString -mapName "tableaddresses"
    $stringresult = $result | Out-String

    # Get hashes from sources and result 
    $Algorithm = "MD5"
    $CustomTestSource01 = Get-CustomHash -StringToHash $textTable -HashAlgorithm $Algorithm 
    $CustomTestSource02 = Get-CustomHash -StringToHash $jsonString -HashAlgorithm $Algorithm 
    $CustomTestDestination = Get-CustomHash -StringToHash $stringresult -HashAlgorithm $Algorithm 

    # check hashes
    if (($CustomTestSource01.Hash -eq "8C1F1B89221E7FE2B827FB7AC8BC4D3D") -and ($CustomTestSource02.Hash -eq "8DF69827B0B34FF4CD0390A0A9B5467A")) {
        if ($CustomTestDestination.Hash -eq "C8F761D85E07562353764B85DECA77D3") {
            Write-Host "Test passed :-)" -ForegroundColor Green
        } else {
            Write-Error "Test failed :-("
        }
    } else {
        Write-Error "Source strings failed" 
    }
} 

catch {
    Write-Error "Error on execution function"
    Write-Error "Test failed :-("
}