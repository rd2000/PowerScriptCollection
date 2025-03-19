<#
    .SYNOPSIS
        Compress file to gzip.

    .PARAMETER InputFile 
        Path to source file.

    .PARAMETER OutputFile 
        Optional, path to the destination file if you want to create the gzip file in a different directory than the source file.

    .EXAMPLE
        Compress-Gzip -InputFile "C:\path\to\source-file.txt"
        Will create: source-file.txt.gz under "C:\path\to\"

        Compress-Gzip -InputFile "C:\path\to\source-file.txt" -OutputFile "C:\anotherpath\destination-file.txt.gz"
        Will create: destination-file.txt.gz under "C:\anotherpath\"
#>
function Compress-Gzip {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [string]$OutputFile
    )

    # Check if the input file exists
    if (-Not (Test-Path $InputFile -PathType Leaf)) {
        Write-Error "File '$InputFile' not found."
        return
    }

    # If no output path has been specified, the default path is set
    if (-Not $OutputFile) {
        $OutputFile = "$InputFile.gz"
    }

    try {
        # Open file and create gzip stream
        $inputStream = [System.IO.File]::OpenRead($InputFile)
        $outputStream = [System.IO.File]::Create($OutputFile)
        $gzipStream = New-Object System.IO.Compression.GzipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)

        # Copy datas to gzip stream
        $inputStream.CopyTo($gzipStream)

        # Close stream
        $gzipStream.Close()
        $outputStream.Close()
        $inputStream.Close()

        Write-Host "The file has been successfully compressed: $OutputFile"
    }
    catch {
        Write-Error "Error while compressing file: $_"
    }
}
