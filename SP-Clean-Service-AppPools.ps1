<#
.DESCRIPTION
	Compares available Service Application IIS Pools to active used.
	Optionally can delete InActive pools to reduce IIS memory usage and streamline farm configuration.

.PARAMETER delete
	Will delete InActive pools from the farm.

.EXAMPLE
	.\SP-Clean-Service-AppPools.ps1
	.\SP-Clean-Service-AppPools.ps1 -delete
	
.NOTES  
	File Name:  SP-Clean-Service-AppPools.ps1
	Author   :  Jeff Jones - spjeff@spjeff.com
	Version  :  1.0
	Modified :  2018-10-02
#>

[CmdletBinding()]
param (
    [switch]$delete
)

# Log
Start-Transcript

# Modules
Add-PSSnapIn Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null

# Clean up IIS service application pools
$avail = (Get-SPServiceApplicationPool).id.guid
$used = (Get-SPServiceApplication).applicationpool.id.guid

# Loop available and check for usage.
Write-Host "Scanning Service Application pools..." -Fore Yellow
foreach ($a in $avail) {
	Write-Host "Checking pool [$a]" -Fore Yellow
	$match = $used |? {$_ -eq $a}
	if ($match) {
		Write-Host " - Active" -Fore Green
		
	} else {
		Write-Host " - InActive" -Fore Red
		if ($delete) {
			Remove-SPServiceApplicationPool $a -Confirm:$false
			Write-Host " - DELETED pool [$a]" -Fore White -Back Red
		}
	}
}

# Log
Stop-Transcript