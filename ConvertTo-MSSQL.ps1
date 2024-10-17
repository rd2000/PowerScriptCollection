function ConvertObj2MSSQL {

    <#
        .SYNOPSIS
        Convert Object to SQL (A generic powershell to sql converter)

        .DESCRIPTION
        Converts a PowerShell object to Microsoft Structured Query Language.
        Reads all MemberTypes of Type NoteProperty or property and optional you can add an inserted and also an updated column.
        This function was developed to provide fast and easy inventury scripts for sysadmins, LIKE me ;-).
        The function doesn't connect the MSSQL server, its only generates the SQL.
          
        .PARAMETER InputObj
        Specifies the input oject

        .PARAMETER TableName
        Specifies the mssql tablename

        .PARAMETER PrimaryKey
        Specifies the primary keyname column. The key must exists on object. 

        .PARAMETER AddInsertedKey
        Add an inserted key column, named: discovered
 
        .PARAMETER AddUpdatedKey
        Add an updated key column, named: updated

        .PARAMETER CreateStatementOnly
        If false, the function generate CREATE Table statement and also INSERTED and UPDATED fields.
        If true, the function will only generate the CREATE Table statement.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        System.Object. Returns a string with the generated SQL.

        .EXAMPLE
        PS> # Get some propertys from Win32_ComputerSystem and create SQL table my_win32_computersystem. Add an inserted and updated keya and move output to clipboard.
        PS> $src=Get-WmiObject -class Win32_ComputerSystem | Select-Object -Property PSComputerName,Username,Model,Domain,Description,DNSHostName,Systemtype,TotalPhysicalMemory,Name
        PS> $sql=obj2SQL -InputObj $src -TableName "my_win32_computersystem" -PrimaryKey "Name" -AddInsertedKey "discovered" -AddUpdatedKey "updated" -CreateStatementOnly $false
        PS> $sql | clip

        .LINK
        Contact: rd2000_git@myitdb.de
    #>
    
    param
    (
        [Parameter(Mandatory=$true)]
        $InputObj,

        [Parameter(Mandatory=$true)]
        [string]$TableName,

        #  Add primary key, 
        # TODO: check if exists keyname on input object and if not, remove pkey or display warning msg
        [Parameter(Mandatory=$true)]
        [string]$PrimaryKey,

        # The keyname for Join (.. AS s ON t.Key = s.Key WHEN MATCHED ...)
        [Parameter(Mandatory=$false)]
        [string]$JoinByKey=$PrimaryKey,

        # Add Discovered Key (for inventury tables)
        [Parameter(Mandatory=$false)]
        [string]$AddInsertedKey,

        # Add UpdatedKey (for inventury tables)
        [Parameter(Mandatory=$false)]
        [string]$AddUpdatedKey,

        [Parameter(Mandatory=$false)]
        [bool]$CreateStatementOnly,

        [Parameter(Mandatory=$false)]
        [int]$CharLength=128,

        [Parameter(Mandatory=$false)]
        [int]$MaxCharLength=512
    )

    # Parameters
    $StartUptime=Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $object=$InputObj
    $table=$TableName
    $primaryKey=$PrimaryKey


    # Create Dynamic Table
    $sql = @()

    $sql += "-- @Script:        PowerShell Object 2 MSSQL"
    $sql += "-- @Description:   Convert a Powershell object to SQL for Microsoft SQL Server"
    $sql += "-- @Version        0.0.1"
    $sql += "--"
    $sql += "-- @WebUrl:        https://myitdb.de"
    $sql += "-- @E-Mail:        rico.schlender@myitdb.de"
    $sql += "--"
    $sql += "-- Host: $env:computername"
    $sql += "-- Created: $StartUptime"
    $sql += ""
    $sql += "" 
    $sql += "-- CREATE TABLE STATEMENT"
    $sql += "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='$table')"
    $sql += "`tCREATE TABLE $table ("

    if ($AddInsertedKey) {  
        $sql += "`t`t$AddInsertedKey datetime,"
    }
    if ($AddUpdatedKey) { 
        $sql += "`t`t$AddUpdatedKey datetime,"
    }

    foreach ($r in ($object | Get-Member)) {
    
        if ($r.MemberType -eq 'NoteProperty' -or $r.MemberType -eq 'Property') {
            
            $colName = $r.Name
            $varType = $r.Definition.Split(" ")[0]

            switch ( $varType ) {

                'string' { $sql += "`t`t[$colName] varchar($CharLength) NOT NULL," } #https://docs.microsoft.com/de-de/sql/t-sql/data-types/char-and-varchar-transact-sql?view=sql-server-ver15
                'int' { $sql += "`t`t[$colName] bigint NOT NULL," }
                'uint64' { $sql += "`t`t[$colName] bigint NOT NULL," }
                'long' { $sql += "`t`t[$colName] bigint NOT NULL," }
                'float' { $sql += "`t`t[$colName] float NOT NULL," }
                'double' { $sql += "`t`t[$colName] real NOT NULL," }
                'datetime' { $sql += "`t`t[$colName] datetime NOT NULL," }
                default { $sql += "`t`t[$colName] varchar($MaxCharLength) NOT NULL," }
            } 
        }
    }

    # Modify last row
    if (!$primaryKey) {
        # If no primary key was add at the end, we remove the comma (,) at end of the row from the last create table column
        $sql[$sql.Length-1] = $sql[$sql.Length-1].Replace(",", "")
    } else {
        # Else we add primary key(s) row on the last table column (without comma) 
        $sql += "`t`tPRIMARY KEY ($primaryKey)"
    }

    $sql += "`t)"
    $sql += "GO"

    if ($CreateStatementOnly) {
        # Return only the SQL CREATE TABLE Statement
        $string=Out-String -InputObject $sql
        return $string
    
    } else {

        $sql += "" 
        $sql += "" 
        $sql += "-- INSERT and UPDATE TABLE STATEMENT"

        $x=0
        $object | ForEach-Object {
            
            $x++

            $sql += "-- ROW $x"
            $sql += "MERGE INTO $table AS t"
            $sql += "`tUSING"
            $sql += "`t`t(SELECT "
        
            foreach ($r in ($object | Get-Member)) {
            
                if ($r.MemberType -eq 'NoteProperty' -or $r.MemberType -eq 'Property') {
                    
                    $colName = $r.Name
                    $colValue = $_.$colName

                    # Create SELECT PART
                    $selectp += "`t`t`t[" + $colName + "]='" + $colValue + "',`n"   
                    
                    # Create UPDATE PART
                    $updatep += "`t`t`t`t[" + $colName + "]=s.[" + $colName + "],`n" 
                    
                    # Create INSERT PART
                    $insertp += "["+ $colName + "], "
                    
                    # Create VALUES PART
                    $valuesp += "s.["+ $colName + "], "
                }
            }
        
            # Add Discovered and Updated Key
            if ($AddInsertedKey) { $sql += "`t`t`t[$AddInsertedKey]=GETDATE()," }
            if ($AddUpdatedKey) { $sql += "`t`t`t[$AddUpdatedKey]=GETDATE()," }

            $sql += $selectp.Trim(",`n")
            $selectp=""
            $sql += "`t`t) AS s"
            $sql += "`tON t.[" + $JoinByKey + "] = s.[" + $JoinByKey +"]"
            $sql += "`tWHEN MATCHED THEN"
            $sql += "`t`tUPDATE SET"

            if ($AddUpdatedKey) {
                $sql += "`t`t`t`t[$AddUpdatedKey]=GETDATE(),"
            } 
            $sql += $updatep.Trim(",`n")
            $updatep=""
            $sql += "`tWHEN NOT MATCHED THEN"
            
            if ($AddInsertedKey) { 
                $sql += "`t`tINSERT ([$AddInsertedKey], " + $insertp.Trim(", ") + ")" 
            } else {
                $sql += "`t`tINSERT (" + $insertp.Trim(", ") + ")" 
            }
            Clear-Variable insertp

            if ($AddUpdatedKey) {
                $sql += "`t`tVALUES (GETDATE(), " + $valuesp.Trim(", ") + ");`n"
            } else {
                $sql += "`t`tVALUES (" + $valuesp.Trim(", ") + ");`n"
            }
            Clear-Variable valuesp             
        }
        
        $EndUptime=Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $sql += "" 
        $sql += "-- End: $EndUptime"

        $string=Out-String -InputObject $sql
        return $string
    }
}