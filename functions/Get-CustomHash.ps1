function Get-CustomHash {
    <#
        .SYNOPSIS
        Create hash from string

        .DESCRIPTION
        This function create a hash from string.
        Simple helper, because PowerShell does not provide a cmdlet to compute the hash of a string.
        See: <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.4>

        .PARAMETER StringToHash
        Specifies the input string

        .PARAMETER HashAlgorithm
        Optional: Specifies the hash algorithm 
        Default SHA256

        The acceptable values for this parameter are:

        - SHA1
        - SHA256
        - SHA383
        - SHA512
        - MD5

        .EXAMPLE
        PS> $result = Get-CustomHash -StringToHash "Hello world"
        PS> $result

            Algorithm Hash
            --------- ----
            SHA256    64EC88CA00B268E5BA1A35678A1B5316D212F4F366B2477232534A8AECA37F3C

        PS> $result = Get-CustomHash -StringToHash "Hello world" -HashAlgorithm 'MD5'
        PS> $result

            Algorithm Hash
            --------- ----
            MD5       3E25960A79DBC69B674CD4EC67A72C62

        .LINK
        https://github.com/rd2000/PowerScriptCollection/
    #>

    param (
        [Parameter(Mandatory=$true)]
        [string]$StringToHash,

        [Parameter(Mandatory=$false)]
        [string]$HashAlgorithm='SHA256'
    )

    $stringAsStream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write($StringToHash)
    $writer.Flush()
    $stringAsStream.Position = 0
    $StringHash = Get-FileHash -InputStream $stringAsStream -Algorithm $HashAlgorithm | Select-Object Algorithm, Hash

    return $StringHash
}