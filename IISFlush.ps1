<#
.SYNOPSIS
	Restart IIS completely each night.
	
.NOTES
	File Name		: IISFlush.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.10
	Last Modified	: 11-16-2017
	
.PARAMETER install
	Typing "IISFlush.ps1 -install" will create a local Task Scheduler job under credentials of the current user. Job runs once daily at 3AM to stop and start the Excel Service Instance.
	
.LINK
	http://www.github.com/spjeff/spadmin/IISFlush.ps1
	
.EXAMPLE
	.\IISFlush.ps1 -i
	.\IISFlush.ps1 -install
#>

param (
    [Alias("i")]
    [switch]$install
)

Function Installer() {
    # Add to Task Scheduler
    Write-Output "  Installing to Task Scheduler..."
    if (!$user) {
        $user = $ENV:USERDOMAIN + "\" + $ENV:USERNAME
    }
    Write-Output "  User for Task Scheduler job: $user"
	
    # Attempt to detect password from IIS Pool (if current user is local admin and farm account)
    $appPools = Get-WMIObject -Namespace "root/MicrosoftIISv2" -Class "IIsApplicationPoolSetting" | Select-Object WAMUserName, WAMUserPass
    foreach ($pool in $appPools) {			
        if ($pool.WAMUserName -like $user) {
            $pass = $pool.WAMUserPass
            if ($pass) {
                break
            }
        }
    }
	
    # Manual input if auto detect failed
    if (!$pass) {
        $pass = Read-Host "Enter password for $user "
    }
	
    # Task Scheduler command
    $cmd = "powershell.exe -ExecutionPolicy Bypass ""$cmdpath"""
	
    # Delete task
    Write-Output "SCHTASKS DELETE"
    SCHTASKS /delete /tn "Daily-IISFlush" /f
    Write-Host "  [OK]" -Fore Green
	
    # Create task
    Write-Output "SCHTASKS CREATE"
    SCHTASKS /create /tn "Daily-IISFlush" /tr "$cmd" /ru $user /rp $pass /rl highest /sc Daily /st 21:00
    Write-Host "  [OK]" -Fore Green
}

function IISFlush() {
    # Reset IIS and verify 100% started.  Twice to be sure.
    Import-Module WebAdministration -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null

    function IISGo {
        NET START W3SVC
        Get-ChildItem "IIS:\AppPools" | % {$n = $_.Name; Start-WebAppPool $n}
        Get-WebSite | Start-WebSite	
    }

    IISRESET
    Start-Sleep 5
    IISGo
    Start-Sleep 5
    IISGo
}

# Main
$cmdpath = $MyInvocation.MyCommand.Path
if ($install) {
    Installer
}
else {
    Start-Transcript
    Get-Date
    IISFlush
    Write-Host "DONE" -Fore Green
    Get-Date
    Stop-Transcript
}