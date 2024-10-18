function Rename-NoteProperty {

    <#
        .SYNOPSIS
        Rename one or multiple NoteProperty of objects.

        .DESCRIPTION
        Rename one or multiple NoteProperty of objects.

        .PARAMETER objects
        Specifies the object for NoteProperty renaming

        .PARAMETER oldNames
        One or multible Key names for search

        .PARAMETER newNames
        One or multible Key names for replace
        Count of keys must be identic to oldNames

        .PARAMETER WarnIfNotFound
        Optional: Warning, if the key for the renaming does not exist

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        System.Object. Returns the object with renamed NoteProperty.

        .EXAMPLE
        PS> #Rename-NoteProperty -objects $myArray -oldNames @('Ports', 'Names', 'Location') -newNames @('Port', 'Name', 'Standort')
        PS> #Rename-NoteProperty -objects $myArray -oldNames 'Ports', 'Names' -newNames 'aPort', 'aName' -WarnIfNotFound $true
        PS> #Rename-NoteProperty -objects $myArray -oldNames 'Ports', 'Names' -newNames 'aPort', 'aName'
        PS> Rename-NoteProperty -objects $myArray -oldNames 'Ports' -newNames 'Port' -WarnIfNotFound $true
    #>

    param (
        [Parameter(Mandatory = $true)]
        [array]$objects,

        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$oldNames,

        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$newNames,

        [Parameter(Mandatory = $false)]
        [bool]$WarnIfNotFound = $false
    )

    # Check if count of old and new names matches
    if ($oldNames.Count -ne $newNames.Count) {
        throw "Count of elements in 'oldNames' and 'newNames' must match."
    }

    foreach ($obj in $objects) {
        for ($i = 0; $i -lt $oldNames.Count; $i++) {
            $oldName = $oldNames[$i]
            $newName = $newNames[$i]

            # Check if NoteProperty exists
            if ($obj.PSObject.Properties[$oldName]) {
                # Save value of old NoteProperty
                $value = $obj.PSObject.Properties[$oldName].Value

                # Remove old NoteProperty
                $obj.PSObject.Properties.Remove($oldName)

                # Add new NoteProperty with the same value
                $obj | Add-Member -NotePropertyName $newName -NotePropertyValue $value
            }
            else {
                # Optional: Write warning if propery not exists 
                if ($WarnIfNotFound) {
                    Write-Warning "The property '$oldName' does not exist in the object and was not renamed"
                }
            }
        }
    }

    return $objects
}