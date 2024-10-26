## Rename NoteProperty of objects

SCRIPT

```powershell
Rename-NoteProperty.ps1
```

DESCRIPTION

__A function to rename one or multiple NoteProperty of objects.__

### A simple test

See examples in the test folder.

```powershell
<# TEST #>

$IncPath = ".\functions\"
.$IncPath"Rename-NoteProperty.ps1"

# Example data
$myArray = @(
    [PSCustomObject]@{ City = "Berlin" },
    [PSCustomObject]@{ City = "Tokyo" },
    [PSCustomObject]@{ City = "Delhi" }
)

Rename-NoteProperty -objects $myArray -oldName 'City' -newName 'Town'
```

### Output

```
Town
----
Berlin
Tokyo
Delhi
```
