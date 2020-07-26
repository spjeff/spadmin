# from https://www.google.com/search?q=powerapps+change+primaryowner&rlz=1C1GCEA_enUS838US838&oq=powerapps+change+primaryowner&aqs=chrome..69i57j0l2.6097j0j7&sourceid=chrome&ie=UTF-8#kpvalbx=_uHcMX7mmDsHOtAbngZTYAg15

# Install
# Install-Module "Microsoft.PowerApps.Powershell" -AllowClobber
# Import-Module "Microsoft.PowerApps.Powershell"
Install-Module "Microsoft.PowerApps.Administration.PowerShell" -AllowClobber
Import-Module "Microsoft.PowerApps.Administration.PowerShell"


# from https://docs.microsoft.com/en-us/power-platform/admin/powerapps-powershell
# Connect
Add-PowerAppsAccount
Get-PowerApp

# Config (all GUID)
$name   = "7ff8f6e3-41f3-4474-a3f9-b9378c78eb1d"
$owner  = $global:currentSession.userId
$owner = "67f75924-9d71-4210-9c04-3c2eb9328286"
$env    = "Default-"

# Update Owner
Write-Host "Update Owner"
Set-AdminPowerAppOwner -AppName $name -AppOwner $owner -Environment $env
Write-Host "Done" -Fore "Green"
