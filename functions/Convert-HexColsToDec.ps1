<#
    .SYNOPSIS
        Converts specified hex columns in a data array to decimal format.

    .DESCRIPTION
        This function accepts an array of PowerShell objects and a list of column names containing hexadecimal values.
        It converts the specified hexadecimal columns to decimal format without modifying the original data.

    .PARAMETER Datas
        Array of objects containing the data to be converted.

    .PARAMETER HexCols
        Array of column names with hexadecimal values to be converted to decimal.

    .RETURNS
        A new array of objects with the specified columns converted to decimal format.

    .EXAMPLE
        $data = @(
            [PSCustomObject]@{ Name = "Entry1"; HexColumn1 = "1A"; HexColumn2 = "FF" },
            [PSCustomObject]@{ Name = "Entry2"; HexColumn1 = "2B"; HexColumn2 = "A0" }
        )
        $convertedData = Convert-HexColumnsToDecimal -Daten $data -HexSpalten @("HexColumn1", "HexColumn2")

        This example converts the hexadecimal columns HexColumn1 and HexColumn2 in $data to decimal values 
        and stores the result in $convertedData without altering the original $data array.

#>
function Convert-HexColsToDec {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Datas,                   # Array of objects containing data to be converted

        [Parameter(Mandatory = $true)]
        [array]$HexCols               # Names of columns containing hexadecimal values
    )

    # Create a copy of the data to keep the original data unchanged
    $result = $Datas | ForEach-Object { $_.PSObject.Copy() }

    # Iterate over each object in the copy and convert hexadecimal values in specified columns
    foreach ($item in $result) {
        foreach ($column in $HexCols) {
            # Check if the column exists and has a valid hex format
            if ($item.PSObject.Properties[$column] -and $item.$column -match '^[0-9A-Fa-f]+$') {
                # Convert from hexadecimal to decimal
                $item.$column = [convert]::ToInt32($item.$column, 16)
            }
        }
    }

    # Return the modified copy of the data
    return $result
}