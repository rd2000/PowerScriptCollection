<# TEST #>

$functionFile = Join-Path (Join-Path $PSScriptRoot "..\functions") "Compress-Gzip.ps1"
. $functionFile

# Test intro
Write-Host "This is a test for function: Compress-Gzip.ps1" -ForegroundColor Blue

$tempDir = Join-Path $env:TEMP "PowerScriptCollection-Compress-Gzip-Test"
$inputFile = Join-Path $tempDir "input.txt"
$outputFile = "$inputFile.gz"
$testContent = @"
PowerScriptCollection
Compress-Gzip test content
Line 3
"@

try {
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory | Out-Null
    }

    Set-Content -Path $inputFile -Value $testContent -Encoding UTF8
    Compress-Gzip -InputFile $inputFile

    if (-not (Test-Path $outputFile -PathType Leaf)) {
        Write-Error "Test failed :-( GZip output file was not created."
        return
    }

    # Read the gzip and validate decompressed content
    $readStream = [System.IO.File]::OpenRead($outputFile)
    $gzipStream = New-Object System.IO.Compression.GzipStream($readStream, [System.IO.Compression.CompressionMode]::Decompress)
    $reader = New-Object System.IO.StreamReader($gzipStream)
    $decompressedContent = $reader.ReadToEnd()

    $reader.Close()
    $gzipStream.Close()
    $readStream.Close()

    $expectedContent = ($testContent -replace "`r`n", "`n").TrimEnd("`n")
    $actualContent = ($decompressedContent -replace "`r`n", "`n").TrimEnd("`n")

    if ($actualContent -eq $expectedContent) {
        Write-Host "Test passed :-)" -ForegroundColor Green
        Write-Host "Created file:" $outputFile
    }
    else {
        Write-Error "Test failed :-( Decompressed content mismatch."
        Write-Host "Expected:"
        Write-Host $expectedContent
        Write-Host "Actual:"
        Write-Host $actualContent
    }
}
catch {
    Write-Error "Error on execution function"
    Write-Error "Test failed :-("
    Write-Error $_
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
