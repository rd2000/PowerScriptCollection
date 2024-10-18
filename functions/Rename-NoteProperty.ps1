<#
    Rename-NoteProperty.ps1

    Example:

    # Example data
    $myArray = @(
        [PSCustomObject]@{ Name = "Server1"; Ports = 80 },
        [PSCustomObject]@{ Name = "Server2"; Ports = 443 },
        [PSCustomObject]@{ Name = "Server3"; Ports = 8080 }
    )

    # Rename join porperties from Ports to Port
    Rename-NoteProperty -objects $myArray -oldName 'Ports' -newName 'Port'

    # Output
    $myArray | Format-Table -AutoSize
#>
function Rename-NoteProperty {
    param (
        [Parameter(Mandatory = $true)]
        [array]$objects,

        [Parameter(Mandatory = $true)]
        [string]$oldName,

        [Parameter(Mandatory = $true)]
        [string]$newName
    )

    foreach ($obj in $objects) {
        # Prüfen, ob die NoteProperty existiert
        if ($obj.PSObject.Properties[$oldName]) {
            # Speichern des Wertes der alten NoteProperty
            $value = $obj.PSObject.Properties[$oldName].Value
            
            # Alte NoteProperty entfernen
            $obj.PSObject.Properties.Remove($oldName)

            # Neue NoteProperty mit dem gleichen Wert hinzufügen
            $obj | Add-Member -NotePropertyName $newName -NotePropertyValue $value
        }
    }

    return $objects
}