<#  
    example.001.ps1
    
    ConvertTo-MSSQL.ps1
    
#> 

Set-Location -Path $PSScriptRoot

$IncPath = "..\functions\"
.$IncPath"ConvertTo-MSSQL.ps1"

# JSON - 10 largest cities
$cities = '[
    {
        "ID": 1,
        "Name": "Tokyo",
        "Population": 37400068,
        "Country": "Japan"
    },
    {
        "ID": 2,
        "Name": "Delhi",
        "Population": 32200000,
        "Country": "India"
    },
    {
        "ID": 3,
        "Name": "Shanghai",
        "Population": 28100000,
        "Country": "China"
    },
    {
        "ID": 4,
        "Name": "São Paulo",
        "Population": 22200000,
        "Country": "Brazil"
    },
    {
        "ID": 5,
        "Name": "Mexico City",
        "Population": 21900000,
        "Country": "Mexico"
    },
    {
        "ID": 6,
        "Name": "Cairo",
        "Population": 21100000,
        "Country": "Egypt"
    },
    {
        "ID": 7,
        "Name": "Dhaka",
        "Population": 21000000,
        "Country": "Bangladesh"
    },
    {
        "ID": 8,
        "Name": "Mumbai",
        "Population": 20600000,
        "Country": "India"
    },
    {
        "ID": 9,
        "Name": "Beijing",
        "Population": 20400000,
        "Country": "China"
    },
    {
        "ID": 10,
        "Name": "Osaka",
        "Population": 19200000,
        "Country": "Japan"
    }
]
'
# convert JSON to Object
$data = $cities | ConvertFrom-Json 

# Create SQL
$sql = ConvertTo-MSSQL `
    -InputObj $data `
    -TableName "persons" `
    -PrimaryKey "ID" `
    -AddInsertedKey "discovered" `
    -AddUpdatedKey "updated" `
    -CreateStatementOnly $false

$sql
