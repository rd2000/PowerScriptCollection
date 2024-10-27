<#  
    Get-CustomHash.example.001.ps1
#> 

Set-Location -Path $PSScriptRoot

$IncPath = "..\functions\"
.$IncPath"Get-CustomHash.ps1"

# The string to hash
$StringToHash = "This is a custom sting!"


# Create MD5 hash
$CustomHash = Get-CustomHash -StringToHash $StringToHash -HashAlgorithm "MD5"
$CustomHash

# Default hash
$CustomHash = Get-CustomHash -StringToHash $StringToHash
$CustomHash

