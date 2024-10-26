<# TEST #>

$IncPath = "..\functions\"
.$IncPath"Rename-NoteProperty.ps1"

# Example data
$myArray = @(
    [PSCustomObject]@{ Firstname = "John"; Surname = "Meier"},
    [PSCustomObject]@{ Firstname = "Lisa"; Surname = "Schmidt" },
    [PSCustomObject]@{ Firstname = "Michael"; Surname = "Müller" }
)

# Now rename porperty from Firstname to Vorname
$output = Rename-NoteProperty -objects $myArray -oldName 'Firstname' -newName 'Vorname'

# Output
$output | Format-Table -AutoSize


# Example data
$myArray = @(
    [PSCustomObject]@{ Firstname = "John"; Surname = "Meier"},
    [PSCustomObject]@{ Firstname = "Lisa"; Surname = "Schmidt" },
    [PSCustomObject]@{ Firstname = "Michael"; Surname = "Müller" }
)

# Now rename porperties from Firstname to Vorname and from Surname to Nachname
$output  = Rename-NoteProperty -objects $myArray -oldName 'Firstname', 'Surname' -newName 'Vorname', 'Nachname'

# Output
$output | Format-Table -AutoSize