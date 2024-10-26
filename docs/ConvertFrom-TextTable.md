## Convert texttable to object

SCRIPT

```powershell
ConvertFrom-TextTable.ps1
```

DESCRIPTION

__Converts a text table into an array of PowerShell objects.__  

This function reads a formatted text table and extracts the data it contains
based on the defined start positions and lengths specified in a JSON string.
The function removes the specified header lines and returns a list of
PowerShell objects containing the extracted data.
        

### A simple test

See examples in the test folder.

```powershell
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
```

### Output

In this example, the output only shows 3 lines from the 10-line object.

```
...
Vorname  : Laura
Nachname : Fischer
PLZ      : 70173
Ort      : Stuttgart
Straße   : Schulstraße 19

Vorname  : Markus
Nachname : Wolf
PLZ      : 28195
Ort      : Bremen
Straße   : Rosenweg 4

Vorname  : Anna
Nachname : Krause
PLZ      : 55116
Ort      : Mainz
Straße   : Brunnenstraße 15
...
```

### A more complex example

```powershell
<#  
    example.002.ps1
    
    ConvertFrom-TextTable.ps1
    
#> 

$IncPath = ".\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"


# Example data (The table as string)
$textTable = @"
+------------------+-------------------+------------------+-------------------+--------------+
| Produkt          | Kategorie         | Verkaufte Menge  | Preis pro Einheit | Gesamtumsatz |
+------------------+-------------------+------------------+-------------------+--------------+
| Laptop           | Elektronik        | 25               | 899.99            | 22499.75     |
| Smartphone       | Elektronik        | 40               | 499.99            | 19999.60     |
| Kühlschrank      | Haushaltsgeräte   | 10               | 699.99            | 6999.90      |
| Fernseher        | Elektronik        | 15               | 1299.99           | 19499.85     |
| Mixer            | Küchengeräte      | 50               | 39.99             | 1999.50      |
| Waschmaschine    | Haushaltsgeräte   | 8                | 549.99            | 4399.92      |
| Kaffeemaschine   | Küchengeräte      | 30               | 99.99             | 2999.70      |
| Staubsauger      | Haushaltsgeräte   | 20               | 149.99            | 2999.80      |
+------------------+-------------------+------------------+-------------------+--------------+
"@


# JSON definition as string
$jsonString = @"
{
    "salesData": {
        "removelines": {
            "header": 3,
            "footer": 1
        },
        "extract": {
            "Produkt": { "start": 2, "length": 18 },
            "Kategorie": { "start": 21, "length": 19 },
            "Verkaufte Menge": { "start": 41, "length": 18 },
            "Preis pro Einheit": { "start": 60, "length": 19 },
            "Gesamtumsatz": { "start": 80, "length": 14 }
        }
    }
}
"@

# Convert simple text table to an PowerShell object
$result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString -mapName "salesData"

# Calculate total sales per category
$groupedByCategory = $result | Group-Object -Property Kategorie | ForEach-Object {
    $category = $_.Name
    $totalSales = ($_.Group | Measure-Object -Property Gesamtumsatz -Sum).Sum

    # Output as custom object
    [PSCustomObject]@{
        Kategorie = $category
        Gesamtumsatz = "{0:N2}" -f $totalSales  # Formatting for better readability
    }
}

# Output
$groupedByCategory
```

### Output

```
Kategorie       Gesamtumsatz
---------       ------------
Elektronik      61.999,20
Haushaltsgeräte 14.399,62
Küchengeräte    4.999,20
```
