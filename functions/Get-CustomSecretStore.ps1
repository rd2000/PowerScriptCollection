<#
.SYNOPSIS
    Get-CustomSecretStore

.DESCRIPTION
    Loads a custom configuration/secret object from a CLIXML file, or creates it if the file does not exist.
    The stored object can contain multiple fields/properties (for example: ApiUrl, ApiToken, Username,
    Password, Tenant, Location, etc.).

    Selected fields can be stored as SecureString values, which are encrypted in CLIXML on Windows
    (typically within the current user context).

    This function is useful for storing API tokens, passwords, and other sensitive values, as well as
    general configuration data.

.PARAMETER Path
    Folder path where the file is stored.

.PARAMETER Filename
    Logical filename (without extension).

.PARAMETER Values
    Hashtable with fields/values to create or update.
    Example: @{ ApiUrl='https://api.example.local'; ApiToken='abc123'; Location='BER' }

.PARAMETER SecureFields
    Field names that should be stored as SecureString.
    Example: 'ApiToken','Password'

.PARAMETER Prefix
    Filename prefix (default: item_)

.PARAMETER Update
    If the file already exists and Values are provided, update/merge the values and save again.
    Without -Update, existing file is only loaded (create-if-missing behavior).

.PARAMETER PromptMissing
    If a provided field value is $null, prompt interactively.
    Secure fields are prompted with -AsSecureString.

.PARAMETER IncludePlainText
    Adds Plain_<FieldName> properties to the returned object for all SecureString fields
    (in memory only, not persisted to file).

.NOTES
    Reserved internal metadata property: _SecureFields
#>
function Get-CustomSecretStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Filename,

        [Parameter(Mandatory = $false)]
        [hashtable]$Values,

        [Parameter(Mandatory = $false)]
        [string[]]$SecureFields = @(),

        [Parameter(Mandatory = $false)]
        [string]$Prefix = "item_",

        [Parameter(Mandatory = $false)]
        [switch]$Update,

        [Parameter(Mandatory = $false)]
        [switch]$PromptMissing,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePlainText
    )

    # Helper: normalize secure field list
    function Get-NormalizedSecureFieldList {
        param([object[]]$List)
        @(
            $List |
            Where-Object { $null -ne $_ -and [string]$_ -ne "" } |
            ForEach-Object { [string]$_ } |
            Select-Object -Unique
        )
    }

    # Helper: convert/create value for storage
    function Convert-ToStoredValue {
        param(
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $false)]$Value,
            [Parameter(Mandatory = $true)][bool]$IsSecure,
            [Parameter(Mandatory = $true)][bool]$PromptForMissing
        )

        if ($IsSecure) {
            if ($Value -is [System.Security.SecureString]) {
                return $Value
            }

            if ($null -eq $Value -or ([string]$Value).Length -eq 0) {
                if ($PromptForMissing) {
                    return (Read-Host "Wert für '$Name' (vertraulich) eingeben" -AsSecureString)
                }
                return $null
            }

            return (ConvertTo-SecureString -String ([string]$Value) -AsPlainText -Force)
        }
        else {
            if ($null -eq $Value) {
                if ($PromptForMissing) {
                    return (Read-Host "Wert für '$Name' eingeben")
                }
                return $null
            }

            return $Value
        }
    }

    # Helper: add or set dynamic property
    function Set-ObjectProperty {
        param(
            [Parameter(Mandatory = $true)][psobject]$Object,
            [Parameter(Mandatory = $true)][string]$Name,
            [Parameter(Mandatory = $false)]$Value
        )

        $existing = $Object.PSObject.Properties[$Name]
        if ($null -ne $existing) {
            $existing.Value = $Value
        }
        else {
            Add-Member -InputObject $Object -MemberType NoteProperty -Name $Name -Value $Value
        }
    }

    # Build file path
    $childName = "{0}{1}.xml" -f $Prefix, $Filename
    $storeFile = Join-Path -Path $Path -ChildPath $childName
    $fileExists = Test-Path -Path $storeFile

    # Load or create base object
    if ($fileExists) {
        $obj = Import-Clixml -Path $storeFile
    }
    else {
        $obj = [pscustomobject]@{}
    }

    # Merge secure field metadata from file + parameter
    $storedSecureFields = @()
    if ($obj.PSObject.Properties["_SecureFields"]) {
        $storedSecureFields = @($obj._SecureFields)
    }

    $allSecureFields = Get-NormalizedSecureFieldList -List (@($storedSecureFields) + @($SecureFields))

    # Create/Update logic
    $shouldSave = $false

    if (-not $fileExists) {
        if (-not $Values -or $Values.Count -eq 0) {
            throw "Die Datei '$storeFile' existiert nicht. Für die Erst-Erstellung bitte -Values (Hashtable) angeben."
        }

        foreach ($key in $Values.Keys) {
            $name = [string]$key
            if ($name -eq "_SecureFields") {
                throw "Der Feldname '_SecureFields' ist reserviert."
            }

            $isSecure = ($allSecureFields -contains $name)
            $storedValue = Convert-ToStoredValue -Name $name -Value $Values[$key] -IsSecure:$isSecure -PromptForMissing:$PromptMissing.IsPresent
            Set-ObjectProperty -Object $obj -Name $name -Value $storedValue
        }

        $shouldSave = $true
    }
    elseif ($Update.IsPresent -and $Values -and $Values.Count -gt 0) {
        foreach ($key in $Values.Keys) {
            $name = [string]$key
            if ($name -eq "_SecureFields") {
                throw "Der Feldname '_SecureFields' ist reserviert."
            }

            $isSecure = ($allSecureFields -contains $name)
            $storedValue = Convert-ToStoredValue -Name $name -Value $Values[$key] -IsSecure:$isSecure -PromptForMissing:$PromptMissing.IsPresent
            Set-ObjectProperty -Object $obj -Name $name -Value $storedValue
        }

        $shouldSave = $true
    }

    # Persist secure field metadata (reserved property)
    Set-ObjectProperty -Object $obj -Name "_SecureFields" -Value (Get-NormalizedSecureFieldList -List $allSecureFields)

    # Save if needed
    if ($shouldSave) {
        $parent = Split-Path -Path $storeFile -Parent
        if (-not (Test-Path -Path $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }

        $obj | Export-Clixml -Path $storeFile
    }

    # Optional: add Plain_<Field> properties in memory only
    if ($IncludePlainText.IsPresent) {
        foreach ($prop in $obj.PSObject.Properties) {
            if ($prop.Name -eq "_SecureFields") { continue }
            if ($prop.Value -is [System.Security.SecureString]) {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prop.Value)
                try {
                    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                }
                finally {
                    if ($bstr -ne [IntPtr]::Zero) {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                    }
                }

                $plainPropName = "Plain_{0}" -f $prop.Name
                Set-ObjectProperty -Object $obj -Name $plainPropName -Value $plain
            }
        }
    }

    return $obj
}