<#
.SYNOPSIS
	Run SMAT (SharePoint Migration Assesment) daily and output to folder.  Download SMAT from https://www.microsoft.com/en-us/download/details.aspx?id=53598
	
.NOTES
	File Name		: Daily-SMAT.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.10
	Last Modified	: 05-22-2017
	
.PARAMETER install
	Typing "Daily-SMAT.ps1 -install" will create a local Task Scheduler job under credentials of the current user. Job runs once daily at 3AM to produce a new current report.
	
.LINK
	http://www.github.com/spjeff/spadmin/Daily-SMAT.ps1
	
.EXAMPLE
	.\Daily-SMAT.ps1 -i
	.\Daily-SMAT.ps1 -install
#>

param (
    [Alias("i")]
    [switch]$install
)

Function Installer() {
	# Add to Task Scheduler
	Write-Output "  Installing to Task Scheduler..."
	if(!$user) {
		$user = $ENV:USERDOMAIN + "\"+$ENV:USERNAME
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
	$cmd = "-ExecutionPolicy Bypass ""$cmdpath"""
	
	# Delete task
	Write-Output "SCHTASKS DELETE"
	SCHTASKS /delete /tn "Daily-SMAT" /f
	Write-Host "  [OK]" -Fore Green
	
	# Create task
	Write-Output "SCHTASKS CREATE"
	SCHTASKS /create /tn "Daily-SMAT" /ru $user /rp $pass /rl highest /st 03:00
	Write-Host "  [OK]" -Fore Green
}

# Main
if ($install) {
	Installer
} else {
	Start-Transcript
	$cmdpath = $MyInvocation.MyCommand.Path
	$cmdfolder = Split-Path $cmdpath
	$date = (Get-Date).ToString("yyyy-MM-dd")
	"  Output: $cmdfolder\$date\"
	.\SMAT.exe -o "$cmdfolder\$date\" -t 2 -q
	Write-Host "DONE" -Fore Green
	Stop-Transcript
}