<#
.SYNOPSIS
	Install SharePoint 2016 and Office Online Server (OOS) on the same PC
	
.DESCRIPTION
	1) Install OOS
	2) Rename 37 registry keys to bypass detection from SETUP.EXE in SharePoint Server.
	3) Install SharEPoint Server 2016
	4) Rename 37 registry keys back
	
	NOTE - Please run PowerShell window as admin

	Comments and suggestions always welcome!  spjeff@spjeff.com or @spjeff
	
.NOTES
	File Name		: Run-OOS-with-SP2016.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.1
	Last Modified	: 10-13-2015
	
.LINK
	http://www.github.com/spjeff/spadmin/run-oos-with-sp2016.ps1
#>

param (
	[switch]$disable
)

# connect HKEY_CLASSES_ROOT
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

# registry keys for Offline Online Server (OOS)
$oos = @"
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109151100000100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109251100000100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109351190400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F10110400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F10170400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F10190400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F10191400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F101A0C00100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00006109F101C0400100000000F01FEC
HKCR:\Installer\Products\00006109151100000100000000F01FEC
HKCR:\Installer\Products\00006109251100000100000000F01FEC
HKCR:\Installer\Products\00006109351190400100000000F01FEC
HKCR:\Installer\Products\00006109F10110400100000000F01FEC
HKCR:\Installer\Products\00006109F10170400100000000F01FEC
HKCR:\Installer\Products\00006109F10190400100000000F01FEC
HKCR:\Installer\Products\00006109F10191400100000000F01FEC
HKCR:\Installer\Products\00006109F101A0C00100000000F01FEC
HKCR:\Installer\Products\00006109F101C0400100000000F01FEC
HKCR:\Installer\Features\00006109151100000100000000F01FEC
HKCR:\Installer\Features\00006109251100000100000000F01FEC
HKCR:\Installer\Features\00006109351190400100000000F01FEC
HKCR:\Installer\Features\00006109F10110400100000000F01FEC
HKCR:\Installer\Features\00006109F10170400100000000F01FEC
HKCR:\Installer\Features\00006109F10190400100000000F01FEC
HKCR:\Installer\Features\00006109F10191400100000000F01FEC
HKCR:\Installer\Features\00006109F101A0C00100000000F01FEC
HKCR:\Installer\Features\00006109F101C0400100000000F01FEC
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-0401-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-0407-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-0409-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-040C-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-0419-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-101F-0C0A-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-1151-0000-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-1152-0000-1000-0000000FF1CE}
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-1153-0409-1000-0000000FF1CE}
"@.Split("`r`n")

# rename keys to bypass detection of OOS from SharePoint SETUP.EXE
if (!$disable) {
	Write-Host "ENABLE BLOCK" -Fore Yellow
	foreach ($key in $oos) {
		if ($key) {
			$split = $key.Split("\\")
			$name = $split[$split.length-1]
			ren "$key" $name.Replace("0F01FEC","0F01FED").Replace("0FF1CE","0FF1DE")
		}
	}
	Write-Host "now ready for SharePoint 2016 SETUP.EXE" -Fore Green
} else {
	Write-Host "DISABLE BLOCK" -Fore Yellow
	foreach ($key in $oos) {
		if ($key) {
			$split = $key.Split("\\")
			$name = $split[$split.length-1]
			ren $key.Replace("0F01FEC","0F01FED").Replace("0FF1CE","0FF1DE") "$name"
		}
	}
	Write-Host "OOS keys back to original names" -Fore Green
}