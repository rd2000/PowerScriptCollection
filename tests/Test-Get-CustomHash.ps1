<# TEST - Do not change the test, please! #>

$IncPath = ".\functions\"
.$IncPath"Get-CustomHash.ps1"

# The test intro
Write-Host "This is a test for function: Get-CustomHash.ps1" -ForegroundColor Blue

# First: Check, if the function has been changed since the last test
if ((Get-FileHash -Path ".\functions\Get-CustomHash.ps1" -Algorithm 'MD5').Hash -ne "649812437DEE98B6E58F4449D2F5841B") {
    Write-Warning "Function has been modified since the last test!"
    Write-Host "If test passed, please adjust the checksum of the function to disable this warning."
}

# The test string must be "Test-Get-CustomHash"
# If you change the test string, the test will be fail.
$TestString = "Test-Get-CustomHash"
$Algorithm = "MD5"
$CustomTest = Get-CustomHash -StringToHash $TestString -HashAlgorithm $Algorithm 

# The test hash must be "5111906AF8764152EE4D118B26CE674C"
# If you change the test hash, the test will be fail.
$TestHash = "5111906AF8764152EE4D118B26CE674C"

# Test
if ($CustomTest.Hash -eq $TestHash ) {
    Write-Host "Test passed :-)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test String:" $TestString
    Write-Host "Hash:" $CustomTest.Hash
    Write-Host "Algorithm:" $CustomTest.Algorithm
} else {
    Write-Error "Test failed :-("
    Write-Host "Test String:" $TestString
    Write-Host "For algorithm:" $CustomTest.Algorithm
    Write-Host "Hash should be:" $CustomTest.Hash
    Write-Host "But the hash is:" $TestHash
}

