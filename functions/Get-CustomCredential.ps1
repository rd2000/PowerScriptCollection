<#
    .SYNOPSIS
    Get a credential

    .DESCRIPTION
    This function loads a credential, if it does not exist it is created.
    
    .PARAMETER Path
    Path from which the credential is loaded or where it is saved.

    .PARAMETER Username
    The username for credential

    .PARAMETER Prefix
    Optional a prefix for credential (Default: cred_)

    .EXAMPLES
    PS> $cred = Get-CustomCredential -Path "C:\Path\To\creds\" -Username "username"
    PS> $cred = Get-CustomCredential -Path "C:\Path\To\creds\" -Username "username" -Prefix "MYPref"
    PS> $cred = Get-CustomCredential -Path $env:APPDATA"\creds\" -Username $env:USERNAME
#>
function Get-CustomCredential {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Username,

        [Parameter(Mandatory=$false)]
        [string]$Prefix = "cred_"

    )

    # Path to credential
    $credPath = $Path + $Prefix + $Username + ".xml"
    
    # The credential already exists
    if ( Test-Path $credPath ) {
        # Load credential
        $cred = Import-CliXml -Path $credPath
    } else {
        # If not exists, create path to new credential
        $parent = split-path $credpath -parent
        if ( -not ( test-Path $parent ) ) {
            New-Item -ItemType Directory -Force -Path $parent
        }
        # Get and Store credential
        $cred = Get-Credential -Message "Password required" -UserName $Username
        $cred | Export-CliXml -Path $credPath
    }

    # Return credential
    return $cred
}