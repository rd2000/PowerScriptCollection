function Get-CustomPassword {
    <#
        .SYNOPSIS
        Get-CustomPassword

        .DESCRIPTION
        This function loads a custom password, if it does not exist it is created.
        If commands do not support credentials, this function can be used to provide plain text passwords. 
        The password is still only saved in encrypted form.
        
        .PARAMETER Path
        Path from which the password is loaded or where it is saved.

        .PARAMETER Filename
        The passwords filename

        .PARAMETER Username
        Optional

        .PARAMETER Password
        Optional

        .PARAMETER Prefix
        Optional a prefix for password (Default: pass_)
    
        .EXAMPLES
        PS> $pass = Get-CustomPassword -Path "C:\Path\To\pass\" -Filename "John"
        PS> $pass = Get-CustomPassword -Path "C:\Path\To\pass\" -Filename "Joe" -Username "JoeJack" -Password "Isja1781sdjS"
        PS> $pass

            Username                     Password PlainPassword
            --------                     -------- -------------
            JoeJack  System.Security.SecureString Isja1781sdjS 

        PS> $loadpass = Get-CustomPassword -Path "C:\Path\To\pass\" -Filename "Joe" -Username "JoeJack"
        PS> $loadpass

            Username                     Password PlainPassword
            --------                     -------- -------------
            JoeJack  System.Security.SecureString Isja1781sdjS 
    #>    

    param (
        [Parameter(Mandatory=$true)]
        $Path,

        [Parameter(Mandatory=$true)]
        $Filename,

        [Parameter(Mandatory=$false)]
        $Username,

        [Parameter(Mandatory=$false)]
        $Password,

        [Parameter(Mandatory=$false)]
        [string]$Prefix = "pass_"
    )
        
    # Path to credential
    $PasswordFile = $Path + $Prefix + $Filename + $Username + ".xml"

    # Create new object
    $obj = $obj = New-Object PSObject

    # If exists, load username and password from file
    if (Test-Path $PasswordFile) {

        $obj = Import-Clixml -Path $PasswordFile
    
    } else {

        # Input username and password (secured)
        if ($Username -eq $null) {
            $Username = Read-Host -Verbose "Usernamen required"
        }

        if ($Password -eq $null) {
            $Password = Read-Host -Verbose "Password for User ${Username} required" -AsSecureString
        } else {
            $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
        }

        # Add to object
        Add-Member -InputObject $obj -MemberType NoteProperty -Name Username -Value $Username
        Add-Member -InputObject $obj -MemberType NoteProperty -Name Password -Value $Password

        # If not exists, create path to new password
        $parent = split-path $PasswordFile -parent
        if ( -not ( test-Path $parent ) ) {
            New-Item -ItemType Directory -Force -Path $parent
        }

        $obj | Export-Clixml -Path $PasswordFile                 
    }

    # Convert password to plain and store on object
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($obj.Password)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    Add-Member -InputObject $obj -MemberType NoteProperty -Name PlainPassword -Value $PlainPassword

    # Return object
    return $obj
}
