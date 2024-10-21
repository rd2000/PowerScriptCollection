function ConvertFrom-TextTable {
    <#
        # ConvertFrom-TextTable.ps1
        TODO Comment
    #>
    
    [Parameter(Mandatory = $true)]
    [string]$textTable 

    [Parameter(Mandatory = $true)]
    [string]$jsonString

    # Konvertiere JSON-String zu einem PowerShell-Objekt
    $json = $jsonString | ConvertFrom-Json


    # Get JSON mainobject name
    $mainObject = $json.PSObject.Properties.Name

    # Teile den Text in einzelne Zeilen auf
    $lines = $textTable -split "`n"

    # Entferne Header und Footer basierend auf JSON
    $removeHeader = $json.$mainObject.removelines.header
    $removeFooter = $json.$mainObject.removelines.footer

    # Behalte nur die relevanten Zeilen (entferne Header und Footer)
    $lines = $lines[$removeHeader..($lines.Length - 1 - $removeFooter)]

    # Definiere Spalten aus JSON
    $spalten = $json.$mainObject.extract

    # Extrahiere die Daten basierend auf den Spalteninformationen
    $result = @()

    foreach ($line in $lines) {
        # Debug-Ausgabe für die aktuelle Zeile
        #Write-Output "Processing line: $line"
        
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
                
                # Debug-Ausgabe für den extrahierten Wert
                #Write-Output "Extracted ${spaltenName}: $wert"
                
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

    # Ausgabe des Arrays
    return $result
}
