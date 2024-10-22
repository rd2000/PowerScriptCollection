# PowerScriptCollection 

A custom collection of powershell functions.

---

## Overview

[Convert Objects to MSSQL](#convert-objects-to-mssql)  
[Join PowerShell Objects](#join-powershell-objects)  
[Rename NoteProperty of objects](#rename-noteproperty-of-objects)  
[Convert TextTable to Object](#convert-texttable-to-object)  

---

## Convert Objects to MSSQL

SCRIPT

```powershell
ConvertTo-MSSQL.ps1
```

DESCRIPTION

__A generic function for converting Powershell objects into MSSQL statements.__  
Convert a PowerShell object to microsoft structured query language. (MSSQL)

Reads all membertypes of type noteproperty or property and optional you can add an inserted and also an updated column.
The function doesn't connect the MSSQL server, its only generates the SQL.
Please remember that the script is not designed for large data sets or for high performance.
It is a generic function that only supports rudimentary SQL data types,
but it can be useful for converting any objects to SQL and storing them in databases.

### A simple test

See examples in the test folder.

```powershell
<# TEST #>

$IncPath = ".\functions\"
.$IncPath"ConvertTo-MSSQL.ps1"

# Sample Datas
$datas = @(
    [PSCustomObject]@{ ID = 1; Name = "John"; Lastname = "Meier" }
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
```

### Output

```SQL
-- CREATE TABLE STATEMENT
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='persons')
        CREATE TABLE persons (
                discovered datetime,
                updated datetime,
                [ID] bigint NOT NULL,
                [Lastname] varchar(128) NOT NULL,
                [Name] varchar(128) NOT NULL,
                PRIMARY KEY (ID)
        )
GO


-- INSERT and UPDATE TABLE STATEMENT
-- ROW 1
MERGE INTO persons AS t
        USING
                (SELECT
                        [discovered]=GETDATE(),
                        [updated]=GETDATE(),
                        [ID]='1',
                        [Lastname]='Meier',
                        [Name]='John'
                ) AS s
        ON t.[ID] = s.[ID]
        WHEN MATCHED THEN
                UPDATE SET
                                [updated]=GETDATE(),
                                [ID]=s.[ID],
                                [Lastname]=s.[Lastname],
                                [Name]=s.[Name]
        WHEN NOT MATCHED THEN
                INSERT ([discovered], [ID], [Lastname], [Name])
                VALUES (GETDATE(), s.[ID], s.[Lastname], s.[Name]);
```

### HISTORY

- 20220205 mod    On CREATE TABLE STATEMENT int => bigint (Because pwsh and mssql int not are the same type.)?
- 20200402 init   First release as a port of a MySQL conversion function.

---

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

---

### Rename NoteProperty of objects

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


---

### Convert texttable to object

SCRIPT

```powershell
ConvertFrom-TextTable.ps1
```

DESCRIPTION

__Converts a text table into an array of PowerShell objects.__  

This function reads a formatted text table and extracts the data it contains
based on the defined start positions and lengths specified in a JSON string.
The function removes the specified header lines and returns a list of
PowerShell objects containing the extracted data.
        

### A simple test

See examples in the test folder.

```powershell
<# TEST #>

$IncPath = ".\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"


# Example data (The table as string)
$textTable = @"
+-----------+-----------+-------+----------------+-------------------+
| Vorname   | Nachname  | PLZ   | Ort            | Straße            |
+-----------+-----------+-------+----------------+-------------------+
| John      | Meier     | 10115 | Berlin         | Hauptstraße 12    |
| Lisa      | Schmidt   | 80331 | München        | Bahnhofstraße 8   |
| Michael   | Müller    | 20095 | Hamburg        | Lindenweg 3       |
| Sarah     | Weber     | 50667 | Köln           | Gartenstraße 22   |
| David     | Schneider | 01067 | Dresden        | Parkallee 7       |
| Laura     | Fischer   | 70173 | Stuttgart      | Schulstraße 19    |
| Markus    | Wolf      | 28195 | Bremen         | Rosenweg 4        |
| Anna      | Krause    | 55116 | Mainz          | Brunnenstraße 15  |
| Peter     | Bauer     | 90403 | Nürnberg       | Kirchplatz 2      |
| Julia     | Zimmermann| 14467 | Potsdam        | Alte Allee 10     |
+-----------+-----------+-------+----------------+-------------------+
"@


# JSON definition as string
$jsonString = @"
{
    "tableaddresses": {
        "removelines": {
            "header": 3,
            "footer": 1
        },
        "extract": {
            "Vorname": { "start": 2, "length": 10 },
            "Nachname": { "start": 14, "length": 10 },
            "PLZ": { "start": 26, "length": 6 },
            "Ort": { "start": 34, "length": 15 },
            "Straße": { "start": 51, "length": 18 }
        }
    }
}
"@

$result = ConvertFrom-TextTable -textTable $textTable -jsonString $jsonString
$result
```

### Output

In this example, the output only shows 3 lines from the 10-line object.

```
...
Vorname  : Laura
Nachname : Fischer
PLZ      : 70173
Ort      : Stuttgart
Straße   : Schulstraße 19

Vorname  : Markus
Nachname : Wolf
PLZ      : 28195
Ort      : Bremen
Straße   : Rosenweg 4

Vorname  : Anna
Nachname : Krause
PLZ      : 55116
Ort      : Mainz
Straße   : Brunnenstraße 15
...
```
