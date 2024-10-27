<#  
    Join-Objects.example.001.ps1
#> 

Set-Location -Path $PSScriptRoot

$IncPath = "..\functions\"
.$IncPath"Join-Objects.ps1"

# Example data
$terminators = @(
    [PSCustomObject]@{ actorID = 1; model = "T-800 / Model 101" }
    [PSCustomObject]@{ actorID = 1; model = "T-850" }
    [PSCustomObject]@{ actorID = 2; model = "T-1000" }
    [PSCustomObject]@{ actorID = 3; model = "T-X" }
)

$actors = @(
    [PSCustomObject]@{ actorID = 1; surname = "Schwarzenegger"; firstname = "Arnold" }
    [PSCustomObject]@{ actorID = 2; surname = "Patrick"; firstname = "Robert"  }
    [PSCustomObject]@{ actorID = 3; surname = "Loken"; firstname = "Kristanna" }
)

# Now join objects based on key 'actorID' 
$joinedResult = Join-Objects -left $terminators -right $actors -key 'actorID'
$joinedResult | Format-Table -AutoSize