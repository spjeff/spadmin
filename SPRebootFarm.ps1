Add-PSSnapIn "Microsoft.SharePoint.PowerShell"
$local = $env:COMPUTERNAME
$localFQDN = $env:COMPUTERNAME + "." + $env:USERDNSDOMAIN
$targets = Get-SPServer |? {$_.Role -ne "Invalid"} |? {$_.Address -ne $local -and $_.Address -ne $localFQDN} | Select Address
$targets |% {Write-Host "Rebooting $($_)"; Restart-Computer $_ -Force}
Restart-Computer -Force
