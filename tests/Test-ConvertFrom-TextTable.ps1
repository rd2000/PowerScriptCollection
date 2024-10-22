<# TEST #>

$IncPath = ".\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"


# Example data (The table as string)
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

$result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString -mapName "tableaddresses"
$result