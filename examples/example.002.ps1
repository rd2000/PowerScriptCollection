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

# Show table
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
