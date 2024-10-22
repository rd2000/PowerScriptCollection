function ConvertFrom-TextTable {
    <#
        .SYNOPSIS
        Converts a text table into an array of PowerShell objects.

        .DESCRIPTION
        This function reads a formatted text table and extracts the data it contains
        based on the defined start positions and lengths specified in a JSON string.
        The function removes the specified header lines and returns a list of
        PowerShell objects containing the extracted data.
        
        .PARAMETER textTable
        A multi-line string representing the text table. This table should be in a
        fixed format where columns are structured by spaces or other delimiters.

        .PARAMETER jsonString
        A JSON string containing the configuration for data extraction. It should define
        the header lines to be removed, as well as the start positions and lengths of the
        columns to be extracted.

        .PARAMETER mapName
        The JSON element Name, where JSON contain the extract datas.

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
                    "header": 2
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

        $result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString -mapName "tableaddresses"
        $result | Format-Table -AutoSize

        This would convert the table into an array of PowerShell objects containing the
        extracted data.
    #>
        
    param (
        [Parameter(Mandatory = $true)]
        [string]$textTable,

        [Parameter(Mandatory = $true)]
        [string]$jsonString,

        [Parameter(Mandatory = $true)]
        [string]$mapName
    )

    # Convert JSON-String to an PowerShell object
    $json = $jsonString | ConvertFrom-Json

    # Access to the relevant parts of the JSON
    $mainObject = $json.$mapName
    $removeHeader = $mainObject.removelines.header
    $removeFooter = $mainObject.removelines.footer
    $cols = $mainObject.extract

    # Split the text into individual lines, regardless of the operating system
    $lines = $textTable -split "`r?`n"

    # Keep only the relevant lines (remove header and footer)
    $lines = $lines[$removeHeader..($lines.Length - 1 - $removeFooter)]

    # Result array
    $result = @()

    foreach ($line in $lines) {
        # Create new object dynamicly
        $columns = [PSCustomObject]@{}

        # Loop each column in JSON 
        foreach ($columnsName in $cols.PSObject.Properties.Name) {
            $start = $cols.$columnsName.start - 1  # Corrected for 0-based indices in PowerShell
            $length = $cols.$columnsName.length

            # Ensure that the start and length are within the line
            if ($start + $length -le $line.Length) {
                # Get value and trim 
                $value = ($line.Substring($start, $length)).Trim()
                
                # Create field dynamicly
                $columns | Add-Member -NotePropertyName $columnsName -NotePropertyValue $value
            } else {
                Write-Output "Error: Invalid range for $columnsName on line: $line"
            }
        }

        # If object not empty, add it to list
        if ($columns.PSObject.Properties.Count -gt 0) {
            $result += $columns
        }
    }

    # Rresult objects array
    return $result
}
