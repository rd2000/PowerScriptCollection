# PowerScriptCollection

**A custom collection of PowerShell functions, scripts, and code snippets.**

This repository focuses on practical PowerShell utilities for transforming data, joining objects, managing secrets, and preparing data for further analysis.

One key tool is [ConvertFrom-TextTable](#convert-texttable-to-object), which transforms unstructured text tables into structured objects.  
[Join-Objects](#join-powershell-objects) and [Rename-NoteProperty](#rename-noteproperty-of-objects) help merge and standardize object data.  
[ConvertTo-MSSQL](#convert-objects-to-mssql) supports storing object data in SQL Server for deeper analysis.

---

## Quickstart

```powershell
# From repository root
. .\functions\Join-Objects.ps1

$left = @([pscustomobject]@{ ID = 1; Name = "John" })
$right = @([pscustomobject]@{ ID = 1; Age = 30 })

Join-Objects -left $left -right $right -key 'ID'
```

---

## Overview

### Functions

- [Convert Objects to MSSQL](#convert-objects-to-mssql)
- [Join PowerShell Objects](#join-powershell-objects)
- [Rename NoteProperty of Objects](#rename-noteproperty-of-objects)
- [Convert TextTable to Object](#convert-texttable-to-object)
- [Get Custom Credential](#get-custom-credential)
- [Get Custom Hash](#get-custom-hash)
- [Get Custom Password](#get-custom-password)
- [Convert Hex Columns to Decimal](#convert-hex-columns-to-decimal)
- [Compress File to Gzip](#compress-file-to-gzip)
- [Expand SQL Template](#expand-sqltemplate)
- [Get Custom SecretStore](#get-custom-secretstore)

### Scripts

- [WebDAV File Downloader](#webdav-file-downloader)

---

## Convert Objects to MSSQL

**A generic function for converting PowerShell objects into MSSQL statements.**  
Converts PowerShell objects to Microsoft SQL Server statements.

See [documentation](docs/ConvertTo-MSSQL.md) for details.

### Screenshot

![ConvertTo-MSSQL screenshot](images/ConvertTo-MSSQL.webp)

## Join PowerShell Objects

**A simple function to join two PowerShell objects based on a matching key.**  
The key must exist on both objects. The function returns merged objects.

See [documentation](docs/Join-Objects.md) for details.

### Screenshot

![Join-Objects screenshot](images/Join-Objects-1.png)

## Rename NoteProperty of Objects

**A function to rename one or multiple NoteProperty fields on objects.**

See [documentation](docs/Rename-NoteProperty.md) for details.

## Convert TextTable to Object

**Converts a text table into an array of PowerShell objects.**

This function reads a formatted text table and extracts data based on defined start positions and lengths provided in a JSON string.  
The function removes specified header lines and returns a list of PowerShell objects.

See [documentation](docs/ConvertFrom-TextTable.md) for details.

### Screenshot

![ConvertFrom-TextTable screenshot](images/ConvertFrom-TextTable.webp)

## Get Custom Credential

**Loads a credential, or creates it if it does not exist.**

## Get Custom Hash

**Creates a hash from a string.**  
Helper function because PowerShell does not provide a built-in cmdlet to compute a hash directly from a string.

Reference: [Get-FileHash](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.4)

### Screenshot

![Get-CustomHash screenshot](images/Get-CustomHash-1.png)

## Get Custom Password

**Loads a custom password, or creates it if it does not exist.**  
Useful when commands do not support credentials directly.  
The password is stored in encrypted form.

## Convert Hex Columns to Decimal

**Converts specified hex columns in an object array to decimal format.**  
Accepts an array of PowerShell objects and a list of column names containing hexadecimal values.  
Converts the selected columns without modifying the original input array.

## WebDAV File Downloader

**PowerScriptCollection - WebDAV File Downloader**  
Downloads image files (JPG, PNG) from a WebDAV resource to a local directory.

## Compress File to Gzip

**Compresses a file to Gzip format.**  
By default, creates the `.gz` file in the same directory as the source file.  
Optionally writes the output file to a different target path.

## Expand SqlTemplate

**Loads a SQL file and replaces placeholders with variable values.**  
Reads a SQL template file and replaces placeholders of the form `{{PLACEHOLDER}}` with matching values from the `-Variables` hashtable.

## Get Custom SecretStore

**Loads a custom configuration/secret object from CLIXML, or creates it if it does not exist.**  
Supports arbitrary fields (for example: `ApiUrl`, `ApiToken`, `Username`, `Password`, `Tenant`).  
Selected fields can be stored as `SecureString` values (encrypted in CLIXML on Windows in the current user context).  
Useful for API tokens, passwords, and general configuration data.
