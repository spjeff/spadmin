<#
.SYNOPSIS
   Specify a new service identity for the SPTraceV4 Windows Service.

.DESCRIPTION
   Specify a new service identity for the SPTraceV4 Windows Service.

.NOTES
   File Name: Set-ServiceIdentityForSPTraceV4Service.ps1
   Version  : 1.0

.PARAMETER AccountName
   Specifies the name of the account which will be used (domain\name).

.EXAMPLE
   PS > .\Set-ServiceIdentityForSPTraceV4Service.ps1 -AccountName "westeros\sp_service"

#>
[CmdletBinding()]
param(
   [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
   [string]$AccountName
)

# Load the SharePoint PowerShell snapin if needed 
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -EA SilentlyContinue) -eq $null) {
   Write-Host "Loading the SharePoint PowerShell snapin..."
   Add-PSSnapin Microsoft.SharePoint.PowerShell
} 

# Get the tracing service.
$svc = (Get-SPFarm).Services | ? { $_.Name -eq "SPTraceV4" }

# Get the managed account from SharePoint
$svcIdentity = Get-SPManagedAccount $AccountName

# Set the tracing service to run under the managed account. $svc.ProcessIdentity.CurrentIdentityType = "SpecificUser"
$svc.ProcessIdentity.ManagedAccount = $svcIdentity
$svc.ProcessIdentity.Update()

# This actually changes the "Run As" account of the Windows service.
$svc.ProcessIdentity.Deploy()

# Add the domain account to the local "Performance Log Users" group
$Domain, $User = $AccountName.Split("\")

([ADSI]("WinNT://$env:COMPUTERNAME/Performance Log Users,group")).Add("WinNT://$Domain/$User")



