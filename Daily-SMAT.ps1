<#
.SYNOPSIS
	Run SMAT (SharePoint Migration Assesment) daily and output to folder.  Download SMAT from https://www.microsoft.com/en-us/download/details.aspx?id=53598
	
.NOTES
	File Name		: Daily-SMAT.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.11
	Last Modified	: 06-29-2017
	
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
    SCHTASKS /delete /tn "Daily-SMAT" /f
    Write-Host "  [OK]" -Fore Green
	
    # Create task
    Write-Output "SCHTASKS CREATE"
    SCHTASKS /create /tn "Daily-SMAT" /tr "$cmd" /ru $user /rp $pass /rl highest /sc Daily /st 21:00
    Write-Host "  [OK]" -Fore Green
}

# Main
$cmdpath = $MyInvocation.MyCommand.Path
$cmdfolder = Split-Path $cmdpath
if ($install) {
    Installer
}
else {
    Start-Transcript
    # Remove folders older than 30 days
    md "$cmdfolder\REPORT" -ErrorAction SilentlyContinue | Out-Null
    $threshold = (Get-Date).AddDays(-30)
    $folders = Get-ChildItem "$cmdfolder\REPORT"
    foreach ($f in $folders) {
        if ($f.LastWriteTime -lt $threshold) {
            Write-Host "Deleting folder $($f.Name)"
            $f | Remove-ChildItem -Confirm:$false
        }
    }

    # Execute SMAT report and output to folder with today's date
    $date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    "  Output: $cmdfolder\$date\"
    Invoke-Expression "$cmdfolder\SMAT\SMAT.exe -o ""$cmdfolder\REPORT\$date\"" -t 8 -q"
    Write-Host "DONE" -Fore Green
    Stop-Transcript
}