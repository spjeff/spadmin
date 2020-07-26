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
$name   = "13ee1859-f35f-4c81-9a9d-4ae19162fca2"
$owner  = $global:currentSession.userId
$owner = "4733cbdb-c00e-46c4-8d99-a2490fde10d9"
$env    = "Default-bfdcda27-6e7a-4490-bb94-5c16225655bc"

# Update Owner
Write-Host "Update Owner"
Set-AdminPowerAppOwner -AppName $name -AppOwner $owner -Environment $env
Write-Host "Done" -Fore "Green"
