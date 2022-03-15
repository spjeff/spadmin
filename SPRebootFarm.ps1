Add-PSSnapIn "Microsoft.SharePoint.PowerShell"
$local = $env:COMPUTERNAME
$localFQDN = $env:COMPUTERNAME + "." + $env:USERDNSDOMAIN
$targets = Get-SPServer |? {$_.Role -ne "Invalid"} |? {$_.Address -ne $local -and $_.Address -ne $localFQDN} | Select Address
$targets |% {$fqdn = "$($_.Address).$($env:USERDNSDOMAIN)"; Write-Host "Rebooting $fqdn"; Restart-Computer $fqdn -Force}
Restart-Computer -Force
