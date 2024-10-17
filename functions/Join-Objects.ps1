function Join-Objects {
    
    <#
        .SYNOPSIS
        Join Objects based on a key.

        .DESCRIPTION
        Join two PS Objects based on an identic key.

        .PARAMETER left
        Specifies the left input oject

        .PARAMETER right
        Specifies the right input oject

        .PARAMETER key
        Specifies the keyname column. The key must exists on both objects. 
        
        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        System.Object. Returns the two joined objects as one.

        .EXAMPLE
        PS> # Join $left object and $right object based on key 'ID' 
        $joined = Join-Objects -left $left -right $right -key 'ID'
    #>
    param (
        [Parameter(Mandatory = $true)]
        [array]$left,

        [Parameter(Mandatory = $true)]
        [array]$right,

        [Parameter(Mandatory = $true)]
        [string]$key
    )

    # Join based on key
    $joined = @()

    foreach ($l in $left) {
        foreach ($r in $right) {
            # Check whether the values of the key match
            if ($l.PSObject.Properties[$key].Value -eq $r.PSObject.Properties[$key].Value) {
                # Dynamic creation of the combined object
                $combinedObject = [PSCustomObject]@{}

                # Copy the properties from the left object
                foreach ($prop in $l.PSObject.Properties) {
                    $combinedObject | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                }

                # Copy the properties from the right object without creating duplicate keys
                foreach ($prop in $r.PSObject.Properties) {
                    if (-not $combinedObject.PSObject.Properties[$prop.Name]) {
                        $combinedObject | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                    }
                }

                # Adding the combined object to the result set
                $joined += $combinedObject
            }
        }
    }

    return $joined
}
