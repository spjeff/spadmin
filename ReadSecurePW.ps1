<#
.SYNOPSIS
	Save Encrypted Passwords to Registry for PowerShell
	
.DESCRIPTION
	Read user text input, convert to secure string, and save to HKCU for usage as credential across many PowerShell scripts.
	
.NOTES
	File Name		: ReadSecurePW.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.01
	Last Modified	: 08-17-2016
	
.LINK
	http://www.github.com/spjeff/spadmin/ReadSecurePW.ps1
#>

param (
    [Alias("c")]
    [switch]$clearSavedPW	
)

Function GetSecurePassword($user) {
    # Registry HKCU folder
    $path = "HKCU:\Software\AdminScript"
    if (!(Test-Path $path)) {
        md $path | Out-Null
    }
    $name = $user
	
    # Do we need to clear old paswords?
    if ($clearSavedPW) {
        Remove-ItemProperty -Path $path -Name $name -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Deleted password OK for $name" -Fore Yellow
        Exit
    }
	
    # Do we have registry HKCU saved password?
    $hash = (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue)."$name"
	
    # Prompt for input
    if (!$hash) {
        $sec = Read-Host "Enter Password for $name" -AsSecureString
        if (!$sec) {
            Write-Error "Exit - No password given"
            Exit
        }
        $hash = $sec | ConvertFrom-SecureString
		
        # Prompt to save to HKCU
        $save = Read-Host "Save to HKCU registry (secure hash) [Y/N]?"
        if ($save -like "Y*") {
            Set-ItemProperty -Path $path -Name $name -Value $hash -Force
            Write-Host "Saved password OK for $name" -Fore Yellow
        }
    }
	
    # Return
    return $hash
}

# Example usage for SharePoint Online (Office 365)
Import-Module Microsoft.Online.SharePoint.PowerShell -WarningAction SilentlyContinue
$admin = "admin@tenant.onmicrosoft.com"
$pass = GetSecurePassword $admin
$secpw = ConvertTo-SecureString -String $pass -AsPlainText -Force
$c = New-Object System.Management.Automation.PSCredential ($admin, $secpw)
Connect-SPOService -URL "https://tenant-admin.sharepoint.com" -Credential $c
Get-SPOSite