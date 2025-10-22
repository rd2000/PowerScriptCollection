function Expand-SqlTemplate {
    <#
    .SYNOPSIS
        Loads a SQL file and replaces placeholders with variable values.

    .DESCRIPTION
        This function reads a SQL template file and replaces placeholders of the form {{PLACEHOLDER}}
        with corresponding values from a hashtable provided via the -Variables parameter.

        Example placeholder format inside the SQL file:
            SELECT * FROM {{TABLE}} WHERE ID = {{ID}};

    .PARAMETER Path
        Path to the SQL file.

    .PARAMETER Variables
        Hashtable containing placeholder names and their replacement values.

    .EXAMPLE
        Expand-SqlTemplate -Path "C:\SQL\query.sql" -Variables @{ TABLE="Users"; ID=123 }

    .NOTES
        - Placeholder names are case-sensitive.
        - If a placeholder is missing in the hashtable, it will remain unchanged.
        - The function returns the final SQL string as output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Variables
    )

    # Check if the SQL file exists
    if (-not (Test-Path $Path)) {
        throw "SQL file not found: $Path"
    }

    # Load the SQL file content as a single string
    $template = Get-Content -Path $Path -Raw

    # Replace placeholders with provided variable values
    foreach ($key in $Variables.Keys) {
        # Match pattern like {{ KEY }} with optional whitespace
        $pattern = "\{\{\s*$key\s*\}\}"

        # Escape special regex characters in the replacement value and Perform the replacement
        $value = [regex]::Escape([string]$Variables[$key])
        $template = [regex]::Replace($template, $pattern, $value)
    }

    # Return the final SQL string
    return $template
}
