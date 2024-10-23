<#  
    example.004.ps1
    
    ConvertFrom-TextTable.ps1
    
#> 

$IncPath = ".\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"


# Example data (The table as string)
$textTable = @"
Load address: $5FA0 Init address: $9513 Play address: $9510
Calling initroutine with subtune 2
Calling playroutine for 3000 frames, starting from frame 0
Middle C frequency is $1168

| Frame | Freq Note/Abs WF ADSR Pul | Freq Note/Abs WF ADSR Pul | Freq Note/Abs WF ADSR Pul | FCut RC Typ V |
+-------+---------------------------+---------------------------+---------------------------+---------------+
|0:00.00| 0374  ... ..  00 099F 800 | 0AF7  ... ..  00 082F 0C0 | 24E1  ... ..  00 081F 680 | 0000 00 Off F |
|0:00.01| ....  ... ..  .. .... ... | ....  ... ..  .. .... ... | ....  ... ..  .. .... ... | .... .. ... . |
|0:00.02| 0342  ... ..  08 088F 641 | 1A14  ... ..  08 052F 500 | ....  ... ..  .. .... 6C0 | D100 F1 Low . |
|0:00.03| 5CED  F-6 CD  81 .... 672 | 5CED  F-6 CD  81 .... ... | ....  ... ..  .. .... ... | EF00 .. ... . |
|0:00.04| 0342 (G-1 93) 41 .... 6A3 | 1A14 (G-4 B7) 41 .... 550 | ....  ... ..  .. .... ... | .... .. ... . |
|0:00.05| ....  ... ..  .. .... 6D4 | ....  ... ..  .. .... ... | ....  ... ..  .. .... 700 | 2B00 .. ... . |
|0:00.06| ....  ... ..  .. .... 705 | ....  ... ..  .. .... ... | ....  ... ..  .. .... ... | .... .. ... . |
|0:00.07| ....  ... ..  .. .... 736 | ....  ... ..  .. .... ... | 1F03  ... ..  08 052F 500 | 6700 .. ... . |
|0:00.08| ....  ... ..  .. .... 767 | ....  ... ..  .. .... 5A0 | 5CED  F-6 CD  81 .... ... | 4900 .. ... . |
|0:00.09| ....  ... ..  .. .... 798 | ....  ... ..  .. .... ... | 1F03 (A#4 BA) 41 .... 550 | .... .. ... . |
"@

# JSON definition as string
$mapString = @"
{
    "siddump": {
        "removelines": {
            "header": 7,
            "footer": 0
        },
        "extract": {
            "Frame": { "start": 2, "length": 7 },
            "v1Freq": { "start": 11, "length": 4 },
            "v1Note/Abs": { "start": 15, "length": 9 },
            "v1WF": { "start": 25, "length": 2 },
            "v1ADSR": { "start": 28, "length": 4 },
            "v1Pul": { "start": 33, "length": 3 },
            "v2Freq": { "start": 39, "length": 4 },
            "v2Note/Abs": { "start": 44, "length": 9 },
            "v2WF": { "start": 53, "length": 2 },
            "v2ADSR": { "start": 56, "length": 4 },
            "v2Pul": { "start": 61, "length": 3 },
            "v3Freq": { "start": 67, "length": 4 },
            "v3Note/Abs": { "start": 72, "length": 9 },
            "v3WF": { "start": 81, "length": 2 },
            "v3ADSR": { "start": 84, "length": 4 },
            "v3Pul": { "start": 89, "length": 3 },
            "FCut": { "start": 95, "length": 4 },
            "RC": { "start": 100, "length": 2 },
            "Typ": { "start": 103, "length": 4 },
            "V": { "start": 107, "length": 1 }
        }
    }
}
"@

# $result | Select-Object -Property v3Freq, v3Note/Abs, v3WF, v3ADSR, v3Pul | FT
# $result | Select-Object -Property v2*, v3* | FT
# $result | Select-Object -Property FCut, RC, Typ, V | FT

$result = ConvertFrom-TextTable -textTable $textTable -jsonString $mapString -mapName "siddump"
$result 