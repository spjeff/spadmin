<#
.SYNOPSIS
	Update all local PowerShell Modules if newer version available.

.PARAMETER install
    Typing "PSModule-AutoUpdate.ps1 -install" will create a local machine Task Scheduler job under credentials of the current user.  Job runs first of each month to download latest PS module with "Update-Module -Force" command.

.NOTES  
	File Name:  PSModule-AutoUpdate.ps1
	Author   :  Jeff Jones  - @spjeff
	Version  :  1.0.0
	Modified :  2019-09-22

.LINK
	https://github.com/spjeff/spadmin
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $false, HelpMessage = 'Use -install -i parameter to add script to Windows Task Scheduler on local machine')]
    [Alias("i")]
    [switch]$install
)

# Installer
if ($install) {
    schtasks /s $_ /create /tn "PSModule-AutoUpdate" /ru $user /rp $pass
}

# Available Modules
$modules = Get-Module -ListAvailable
foreach ($mod in $modules) {
    $module = $mod.Name
    $available = Find-Module $module

    if ($available) {
        # Current Module
        $current = (Get-Module -ListAvailable | ? { $_.Name -eq $module })
        # Compare Module Version
        if ($available.Version -gt $current.Version) {
            # Execute Module Update
            Write-Host " - UPDATE AVAILABLE" -ForegroundColor Yellow
            Remove-Item (Split-Path $current.Path) -Confirm:$false -Force
            Install-Module $module -AllowClobber -Force
        }
    }
}