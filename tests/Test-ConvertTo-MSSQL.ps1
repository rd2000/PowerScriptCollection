<# TEST #>

$IncPath = ".\functions\"
.$IncPath"ConvertTo-MSSQL.ps1"

# Sample Datas
$datas = @(
    [PSCustomObject]@{ ID = 1; Name = "John"; Lastname = "Meier" }
    [PSCustomObject]@{ ID = 2; Name = "Lisa"; Lastname = "Schmidt" }
    [PSCustomObject]@{ ID = 3; Name = "Michael"; Lastname = "Müller" }
    [PSCustomObject]@{ ID = 4; Name = "Sarah"; Lastname = "Weber" }
    [PSCustomObject]@{ ID = 5; Name = "David"; Lastname = "Schneider" }
    [PSCustomObject]@{ ID = 6; Name = "Laura"; Lastname = "Fischer" }
    [PSCustomObject]@{ ID = 7; Name = "Markus"; Lastname = "Wolf" }
    [PSCustomObject]@{ ID = 8; Name = "Anna"; Lastname = "Krause" }
    [PSCustomObject]@{ ID = 9; Name = "Peter"; Lastname = "Bauer" }
    [PSCustomObject]@{ ID = 10; Name = "Petra"; Lastname = "Zimmermann" }
)

# Create SQL
$sql = ConvertTo-MSSQL `
    -InputObj $datas `
    -TableName "persons" `
    -PrimaryKey "ID" `
    -AddInsertedKey "discovered" `
    -AddUpdatedKey "updated" `
    -CreateStatementOnly $false

$sql