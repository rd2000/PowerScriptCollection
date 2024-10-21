function ConvertFrom-TextTable {

        <#
            .SYNOPSIS
            Wandelt eine Texttabelle in ein Array von PowerShell-Objekten um.
    
            .DESCRIPTION
            Diese Funktion liest eine formatierte Texttabelle und extrahiert die darin enthaltenen Daten
            gemäß den definierten Startpositionen und Längen, die in einem JSON-String angegeben sind.
            Die Funktion entfernt die angegebenen Header- und Footer-Zeilen und gibt eine Liste von
            PowerShell-Objekten zurück, die die extrahierten Daten enthalten.
    
            .PARAMETER textTable
            Eine mehrzeilige Zeichenkette, die die Texttabelle darstellt. Diese Tabelle sollte in einem
            festen Format vorliegen, in dem die Spalten durch Leerzeichen oder andere Trennzeichen
            strukturiert sind.
    
            .PARAMETER jsonString
            Ein JSON-String, der die Konfiguration für die Datenextraktion enthält. Er sollte die
            Header- und Footer-Zeilen definieren, die entfernt werden sollen, sowie die Startpositionen
            und Längen der zu extrahierenden Spalten.
    
            .EXAMPLE
            $textTable = @"
            Vorname Nachname  PLZ   Ort       Straße
            ------- --------  ---   ---       ------
            John    Meier     10115 Berlin    Hauptstraße 12
            "@
    
            $jsonString = @"
            {
                "tableaddresses": {
                    "removelines": {
                        "header": 2,
                        "footer": 1
                    },
                    "extract": {
                        "Vorname": { "start": 1, "length": 10 },
                        "Nachname": { "start": 13, "length": 10 },
                        "PLZ": { "start": 25, "length": 6 },
                        "Ort": { "start": 32, "length": 15 },
                        "Straße": { "start": 48, "length": 18 }
                    }
                }
            }
            "@
    
            $result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString
            $result | Format-Table -AutoSize
    
            Dies würde die Tabelle in ein Array von PowerShell-Objekten umwandeln, das die
            extrahierten Daten enthält.
        #>

        
    param (
        [Parameter(Mandatory = $true)]
        [string]$textTable,

        [Parameter(Mandatory = $true)]
        [string]$jsonString
    )

    # Konvertiere JSON-String zu einem PowerShell-Objekt
    $json = $jsonString | ConvertFrom-Json

    # Zugriff auf die relevanten Teile des JSON
    $mainObject = $json.tableaddresses
    $removeHeader = $mainObject.removelines.header
    $removeFooter = $mainObject.removelines.footer
    $spalten = $mainObject.extract

    # Teile den Text in einzelne Zeilen auf, unabhängig vom Betriebssystem
    $lines = $textTable -split "`r?`n"

    # Behalte nur die relevanten Zeilen (entferne Header und Footer)
    $lines = $lines[$removeHeader..($lines.Length - 1 - $removeFooter)]

    # Array zum Speichern der Ergebnisse
    $result = @()

    foreach ($line in $lines) {
        # Dynamisch ein neues Objekt erstellen
        $columns = [PSCustomObject]@{}

        # Für jede Spalte in der JSON-Definition
        foreach ($spaltenName in $spalten.PSObject.Properties.Name) {
            $start = $spalten.$spaltenName.start - 1  # Korrigiert für 0-basierte Indizes in PowerShell
            $length = $spalten.$spaltenName.length

            # Sicherstellen, dass Start und Länge innerhalb der Zeile liegen
            if ($start + $length -le $line.Length) {
                # Wert extrahieren und trimmen
                $wert = ($line.Substring($start, $length)).Trim()
                
                # Dynamisch das Feld hinzufügen
                $columns | Add-Member -NotePropertyName $spaltenName -NotePropertyValue $wert
            } else {
                Write-Output "Error: Invalid range for $spaltenName on line: $line"
            }
        }

        # Objekt zur Liste hinzufügen, wenn nicht leer
        if ($columns.PSObject.Properties.Count -gt 0) {
            $result += $columns
        }
    }

    # Rückgabe des Arrays von Objekten
    return $result
}
