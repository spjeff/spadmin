<#
.SYNOPSIS
	Restart the Excel service instance daily.
	
.NOTES
	File Name		: RestartExcel.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.12
	Last Modified	: 11-16-2017
	
.PARAMETER install
	Typing "Daily-RestartExcel.ps1 -install" will create a local Task Scheduler job under credentials of the current user. Job runs once daily at 3AM to stop and start the Excel Service Instance.
	
.LINK
	http://www.github.com/spjeff/spadmin/Daily-RestartExcel.ps1
	
.EXAMPLE
	.\Daily-RestartExcel.ps1 -i
	.\Daily-RestartExcel.ps1 -install
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
    SCHTASKS /delete /tn "Daily-RestartExcel" /f
    Write-Host "  [OK]" -Fore Green
	
    # Create task
    Write-Output "SCHTASKS CREATE"
    SCHTASKS /create /tn "Daily-RestartExcel" /tr "$cmd" /ru $user /rp $pass /rl highest /sc Daily /st 21:00
    Write-Host "  [OK]" -Fore Green
}

function RestartExcel() {
    # Stop
    $servers = @()
    $si = Get-SPServiceInstance |? {$_.Type -eq "Excel Calcuation Services"}
    foreach ($i in $si) {
        if ($i.Status -eq "Online") {
            $i.Unprovision()
            $s = $i.Server.Address
            $servers += $s
            Write-Host "UNProvision ECS on $s"
        }
    }
    Start-Sleep 10
    # Start
    foreach ($s in $servers) {
        $server = Get-SPServer $s
        $i = Get-SPServiceInstance |? {$_.Type -eq "Excel Calcuation Services" -and $_.Server -eq $server}
        if ($i.Status -ne "Online") {
            $i.Provision()
            Write-Host "Provision ECS on $s"
        }
    }
}

# Main
$cmdpath = $MyInvocation.MyCommand.Path
$cmdfolder = Split-Path $cmdpath
if ($install) {
    Installer
}
else {
    Start-Transcript
    Get-Date
    RestartExcel
    Write-Host "DONE" -Fore Green
    Get-Date
    Stop-Transcript
}