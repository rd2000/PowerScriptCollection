<#  
    Get-CustomSecretStore.example.001.ps1
#> 

Set-Location -Path $PSScriptRoot

$IncPath = "..\functions\"
.$IncPath"Get-CustomSecretStore.ps1"


$cfg = Get-CustomSecretStore `
    -Path "$env:APPDATA\creds\" `
    -Filename "secret.example.001" `
    -Values @{
        MySecret1 = $null
        MySecret2 = $null
    } `
    -SecureFields "MySecret2" `
    -PromptMissing `
    -IncludePlainText

$sec1 = $cfg.MySecret1
$sec2 = $cfg.MySecret2
$sec3 = $cfg.Plain_MySecret2

Write-Host $sec1
Write-Host $sec2
Write-Host $sec3


# First Run:

<#

PS C:\PowerScriptCollection\examples> .\Get-CustomSecretStore.example.001.ps1
Wert für 'MySecret2' (vertraulich) eingeben: *****************
Wert für 'MySecret1' eingeben: Mein Geheimnis
Mein Geheimnis
System.Security.SecureString
Vertrauliche Info


PS C:\PowerScriptCollection\examples> type C:\Users\username\AppData\Roaming\creds\item_m42-api.xml

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <Obj RefId="0">
    <TN RefId="0">
      <T>System.Management.Automation.PSCustomObject</T>
      <T>System.Object</T>
    </TN>
    <MS>
      <SS N="MySecret2">01000000d08c9ddf0115d1118c7a00c04fc297eb01000000234dcb3b06fa6443ad13e09ae91b9e50000000000200000000001066000000010000200000004119fd693eeab23a49e2f5f959e758e932582327bdf07bada40c3bf7488e9f67000000000e80000000020000200000003c4814c98d82f94533ae50c81ebdadc5a018515fd12aa988b898f8b68e36e2f530000000d6681a81a02f3d7237fa30761267e1233b84e4e84a4646d3814dd377fe4ccbcbb3496a1223a2d60c68207cb31d6ce2d9400000006a51c35ebcf3b4a7f7ce9de6c9305e4d1b6464b655af0b6da72eebffd648982ecb3e4726c2a5daeac1168865c9d252c3548af05627b5f2b958939896fa0d2f6d</SS>
      <S N="MySecret1">Mein Geheimnis</S>
      <S N="_SecureFields">MySecret2</S>
    </MS>
  </Obj>
</Objs>

#>


# Second Run:

<#
C:\PowerScriptCollection\examples> .\Get-CustomSecretStore.example.001.ps1
Mein Geheimnis
System.Security.SecureString
Vertrauliche Info
#>