# from https://www.google.com/search?q=powerapps+change+primaryowner&rlz=1C1GCEA_enUS838US838&oq=powerapps+change+primaryowner&aqs=chrome..69i57j0l2.6097j0j7&sourceid=chrome&ie=UTF-8#kpvalbx=_uHcMX7mmDsHOtAbngZTYAg15

# Install
# Install-Module "Microsoft.PowerApps.Powershell" -AllowClobber
# Import-Module "Microsoft.PowerApps.Powershell"
Install-Module "Microsoft.PowerApps.Administration.PowerShell" -AllowClobber
Import-Module "Microsoft.PowerApps.Administration.PowerShell"

# Install Manual (NUPKG extract ZIP)
# from https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/working-with-packages/manual-download?view=powershell-7
# Import-Module "C:\Program Files\WindowsPowerShell\Modules\Microsoft.PowerApps.Powershell\1.0.13\Microsoft.PowerApps.PowerShell.psm1"
# Unblock-File "C:\Program Files\WindowsPowerShell\Modules\Microsoft.PowerApps.Powershell\1.0.13\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
# [reflection.assembly]::loadfile("C:\Program Files\WindowsPowerShell\Modules\Microsoft.PowerApps.Powershell\1.0.13\Microsoft.IdentityModel.Clients.ActiveDirectory.dll")
# Get-Command *powerapp*

# Connect
# from https://docs.microsoft.com/en-us/power-platform/admin/powerapps-powershell
Add-PowerAppsAccount -Endpoint "usgov"
Get-PowerApp

# Config (all GUID)
$name   = "d0877074-9a19-4a05-8691-c9b7bb783e79"
$owner  = $global:currentSession.userId
$owner = "d9bcbbf0-a86f-42e0-9c6c-05a2ca387b70"
$env    = "Default-7e6c5822-c9ff-4a02-99dd-6d286ea8af74"

# Update Owner
Write-Host "Update Owner"
Set-AdminPowerAppOwner -AppName $name -AppOwner $owner -Environment $env
Write-Host "Done" -Fore "Green"
