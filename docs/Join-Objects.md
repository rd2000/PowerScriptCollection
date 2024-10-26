## Join PowerShell Objects

SCRIPT

```powershell
Join-Objects.ps1
```

DESCRIPTION

__A simple function to join two PS Objects based on an identic key.__  
The key must exists on both objects. After join returns the two objects as one.

### A simple test

See examples in the test folder.

```powershell
<# TEST #>

$IncPath = ".\functions\"
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
```

### Output

```
ID Name Age
-- ---- ---
 1 John  30
 2 Jane  25
```
