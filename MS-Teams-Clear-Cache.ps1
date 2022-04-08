<#
.DESCRIPTION
	Purge inactive local MS Teams profile data.  Comments and suggestions always welcome.
.EXAMPLE
	.\MS-Teams-Clear-Cache.ps1
	
.NOTES  
	File Name:  MS-Teams-Clear-Cache.ps1
	Author   :  Jeff Jones
	Version  :  1.2
	Modified :  2022-04-08
#>

function Main() {
	# GUI 
	Add-Type -AssemblyName PresentationFramework
	Add-Type -AssemblyName System.Windows.Forms
	
	# Close MS Teams
	Get-Process teams | Stop-Process -Confirm:$false -Force
	
    # Discover all local users https://stackoverflow.com/questions/9725521/how-to-get-the-parents-parent-directory-in-powershell
    $profile    = $env:USERPROFILE
    $root       = (Get-ChildItem $profile)[0].Parent.Parent.FullName
    $allUsers   = $root | Get-ChildItem -Directory -Exclude "Public"

    # Compare to Active Directory https://techibee.com/active-directory/powershell-search-for-a-user-without-using-ad-module/2872
    foreach ($u in $allUsers) {
        # Define scope
        $name       = $u.Name
        $ldap       = "(&(ObjectCategory=Person)(ObjectClass=User)(SamAccountName=" + $name + "))"
        $search     = [adsisearcher]$ldap
        $results    = $search.FindAll()

        # Search Active Directory
        if ($results.Count -eq 0) {
            Write-Host "NOT FOUND [" + $name + "] IN AD.  DELETE FOLDER." -ForegroundColor "Yellow"
            Remove-Item "$root\$name" -Force
        } else {
            Write-Host "FOUND [" + $name + "] IN AD" -ForegroundColor "Green"
        }
    }

	# Popup dialog
	[System.Windows.MessageBox]::Show('Succesfully cleared local folder.','Microsoft Teams - Cache Cleared','OK','Information')
	
	# Launch MS Teams
	$ad = $env:LOCALAPPDATA
	$proc = "$ad\Microsoft\Teams\Update.exe"
	$arg = "--processStart ""Teams.exe"""
	Start-Process $proc -ArgumentList $arg	
}

# DOWNLOADN AND INSTALL TEAMS

function downalodandInstall()
{
    $downloadpath ="https://go.microsoft.com/fwlink/p/?LinkID=2187217&clcid=0x4009&culture=en-in&country=IN&Lmsrc=groupChatMarketingPageWeb&Cmpid=directDownloadv2Win64"
    Invoke-WebRequest -Uri $downloadpath -OutFile $env:TEMP\MSTeamsSetup_c_l_.exe
    Invoke-Expression $env:TEMP\MSTeamsSetup_c_l_.exe
}

# UNISTALL TEAMS

function unInstallTeams($path) {
    $clientInstaller = "$($path)\Update.exe"
    try {
        $process = Start-Process -FilePath "$clientInstaller" -ArgumentList "–uninstall /s" -PassThru -Wait -ErrorAction STOP
        if ($process.ExitCode -ne 0)
        {
            Write-Error "UnInstallation failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
# Open Log
$prefix = $MyInvocation.MyCommand.Name
$host.UI.RawUI.WindowTitle = $prefix
$stamp = Get-Date -UFormat "%Y-%m-%d-%H-%M-%S"
Start-Transcript "$PSScriptRoot\log\$prefix-$stamp.log"
$start = Get-Date


Main

# UNCOMMENT BELOW LINE INSTALLATION

# downalodandInstall

# UNCOMMENT BELOW LINE UN-INSTALLATION
$localAppData="$($env:LOCALAPPDATA)\Microsoft\Teams"
#unInstallTeams

# Close Log
$end = Get-Date
$totaltime = $end - $start
Write-Host "`nTime Elapsed: $($totaltime.tostring("hh\:mm\:ss"))"
Stop-Transcript