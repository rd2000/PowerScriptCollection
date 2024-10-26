<#
    Power Script Collection - WebDav File Downloader

    .SYNOPSIS
    Download images (jpg, png) from WebDav resource and store the images to a local directory

    .DESCRIPTION
    This script download images, or if you want, any filetype from a WebDav resource to a local directory.
    The script creates a list containing the links to the images on the web resource
    and loads them only once into the directory.

    .EXAMPLE
    Set uri to web resource ($uri) and your local destination directory ($dstdir)
    and then run the script. On the first run, you need your credential. 

#>

# Inlcude functions
$IncPath = "..\functions\"
.$IncPath"Get-CustomCredential.ps1"

# File source (webresource)
$uri = "https://webdav.domain.com/path/to/images/"

# File destination directory
$dstdir = "$env:userprofile\Pictures\${ResourceName}"

# Filename for Link List
$ResourceName = "MyWebDavImages"
$AppDirectory = "PSC_WebDav_File_Downloader"

try {
    
    # Get credential
    $cred = Get-CustomCredential -Path $env:APPDATA"\creds\" -Username "username"

    # Create destination if not exists
    if (-not ( Test-Path $dstdir ) )
    {
        New-Item $dstdir -ItemType Directory
    }

    # AppDirectory 
    $LinkListDir = $env:APPDATA + "\" + $AppDirectory

    if ( Test-Path $LinkListDir  ) 
    {
        # Get link list from resource file
        $LinkList = Get-Content -Path "$LinkListDir\$ResourceName"    
    } 
    else {
        # If link list directory for resource not exists,
        # create them an create a new file with value 0
        New-Item $LinkListDir -ItemType Directory
        New-Item "$LinkListDir\$ResourceName" -ItemType File -Value 0
        $LinkList = Get-Content -Path "$LinkListDir\$ResourceName"  
    }

    # Get index from resource
    $req = Invoke-WebRequest -Credential $cred -Uri $uri

    # Only specified file types
    #$files = $req.Links | Where-Object -Property 'href' -ilike '*.jpg*' 
    $files = $req.Links | Where-Object { $_.href -ilike '*.jpg*' -or $_.href -ilike '*.png*' }
        
    # Download new files
    $i = 0
    $files | ForEach-Object { 
        
        $filename = $uri + $_.href
        $destfile = $dstdir + "\" + $_.href

        if (-not ($LinkList.Contains($filename))) {
            Write-Host "Start Download Source: [$filename] Destination: [$destfile]"
            Invoke-WebRequest -Credential $cred -Uri $filename  -OutFile $destfile
            Add-Content -Path "$LinkListDir\$ResourceName" -Value $filename
            $i++
        }
    }

    if ( $i -eq 0 ) {
        Write-Host "No new files found to download." -ForegroundColor Yellow
    } else {
        Write-Host "Downloaded files: ${i}" -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
}