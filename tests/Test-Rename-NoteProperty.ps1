<# TEST #>

$IncPath = ".\functions\"
.$IncPath"Rename-NoteProperty.ps1"

# Example data
$myArray = @(
    [PSCustomObject]@{ Name = "Server1"; Ports = 80 },
    [PSCustomObject]@{ Name = "Server2"; Ports = 443 },
    [PSCustomObject]@{ Name = "Server3"; Ports = 8080 }
)

# Now rename join porperties from Ports to Port
Rename-NoteProperty -objects $myArray -oldName 'Ports' -newName 'Port'

# Output
$myArray | Format-Table -AutoSize