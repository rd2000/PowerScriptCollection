<#  
    example.003.ps1
    
    ConvertFrom-TextTable.ps1
    
#> 

$IncPath = ".\functions\"
.$IncPath"ConvertFrom-TextTable.ps1"


# Example data (The table as string)
$textTable = @"


Port      Name               Status       Vlan       Duplex  Speed Type 
Gi1/0/1   INT P01/01         connected    4008       a-full a-1000 10/100/1000BaseTX
Gi1/0/2   INT P01/02         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/3   INT P01/03         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/4   INT P01/04         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/5   INT P01/05         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/6   INT P01/06         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/7   INT P01/07         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/8   INT P01/08         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/9   INT P01/09         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/10  INT P01/10         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/11  INT P01/11         connected    4018       a-full a-1000 10/100/1000BaseTX
Gi1/0/12  INT P01/12         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/13  INT P01/13         connected    4018       a-full a-1000 10/100/1000BaseTX
Gi1/0/14  INT P01/14         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/15  INT P01/15         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/16  INT P01/16         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/17  INT P01/17         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/18  INT P01/18         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/19  INT P01/19         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/20  INT P01/20         connected    4018       a-full a-1000 10/100/1000BaseTX
Gi1/0/21  INT P01/21         connected    4010       a-full a-1000 10/100/1000BaseTX
Gi1/0/22  INT P01/22         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/23  INT P01/23         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/24  INT P01/24         notconnect   4018         auto   auto 10/100/1000BaseTX
Gi1/0/25  NOD router-12 1    connected    trunk      a-full a-1000 1000BaseLX SFP
Gi1/0/26                     disabled     1            auto   auto Not Present
Gi1/0/27                     disabled     1            auto   auto Not Present
Gi1/0/28                     disabled     1            auto   auto Not Present
Po1       NOD router-12      connected    trunk      a-full a-1000 
Fa0                          disabled     routed       auto   auto 10/100BaseTX

"@


# JSON definition as string
$mapString = @"
{
    "show interfaces status": {
        "removelines": {
            "header": 3,
            "footer": 1
        },
        "extract": {
            "Port": { "start": 1, "length": 10 },
            "Name": { "start": 11, "length": 19 },
            "Status": { "start": 30, "length": 13 },
            "Vlan": { "start": 43, "length": 11 },
            "Duplex": { "start": 54, "length": 7 },
            "Speed": { "start": 61, "length": 6 },
            "Type": { "start": 68, "length": 17 }
        }
    }
}
"@

$result = ConvertFrom-TextTable -textTable $textTable -jsonString $mapString -mapName "show interfaces status"
$result