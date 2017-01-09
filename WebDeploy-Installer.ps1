#============================================================================
#  Web Deploy Installer
#============================================================================
#  Filename:	WebDeploy-Installer.ps1
#
#  Purpose:		Install Web Deploy ZIP package to local IIS SharePoint site
#				given two parameters ZIP file and IIS website name.
#============================================================================
param (
	[string]$zip 				# example "c:\temp\HelloTime.zip"
	[string]$iisWebSiteName		# example "Portal"
)

# Plugin
Import-Module WebAdministration -ErrorAction SilentlyContinue | Out-Null
Add-PSSnapin WDeploySnapIn3.0 -ErrorAction SilentlyContinue | Out-Null

# IIS Virtual Directory
New-WebVirtualDirectory -Name "_webapi" -PhysicalPath "c:\inetpub\webapi\" -Site $iisWebSiteName

# Web Deploy ZIP
$file = Split-Path $zip -Leaf
$params = Get-WDParameters $zip
$params."IIS Web Application Name" = "_webapi/$file"
Restore-WDPackage -Package $zip -Paramters $params