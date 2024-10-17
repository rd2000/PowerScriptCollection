# PSFunctions

A custom collection of powershell scripts.

---

## Overview

### [ConvertTo-MSSQL.ps1](#convertto-mssql.ps1)
### [Join-Objects.ps1](#join-objects.ps1)

---

## [ConvertTo-MSSQL.ps1]

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

## [Join-Objects.ps1]

DESCRIPTION

__A simple function to join two PS Objects based on an identic key.__  
The key must exists on both objects. After join returns the two objects as one.

### A simple test

See examples in the test folder.

<# TEST #>

```powershell
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
