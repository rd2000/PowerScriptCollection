<# TEST #>

$IncPath = "..\functions\"
.$IncPath"Join-Objects.ps1"

# Example data
$left = @(
    [PSCustomObject]@{ ID = 1; Name = "John" }
    [PSCustomObject]@{ ID = 2; Name = "Jane" }
    [PSCustomObject]@{ ID = 3; Name = "Jim" }
)

$right = @(
    [PSCustomObject]@{ ID = 1; Age = 30 }
    [PSCustomObject]@{ ID = 2; Age = 25 }
    [PSCustomObject]@{ ID = 4; Age = 40 }
)

# Now join objects based on key 'ID' 
$joinedResult = Join-Objects -left $left -right $right -key 'ID'
$joinedResult | Format-Table -AutoSize