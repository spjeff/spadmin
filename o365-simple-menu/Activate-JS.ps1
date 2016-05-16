param(
   [string]$SiteUrl,   
   [string]$UserName, 
   [string]$Password   
)

. ".\UserCustomActions.ps1"

<#  
.LINK
	from @vgrem https://gist.github.com/vgrem/e00da5f4f5dd847943d0
.SYNOPSIS  
    Enable jQuery and Custom Library        
.DESCRIPTION  
    Enable jQuery and Custom Library in Office 365/SharePoint Online site 
.EXAMPLE
    .\Activate-JS.ps1 -SiteUrl "https://tenant-public.sharepoint.com" -UserName "username@tenant.onmicrosoft.com" -Password "password"
#>
Function Activate-JS([string]$SiteUrl,[string]$UserName,[string]$Password)
{
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $context.Credentials = Get-SPOCredentials -UserName $UserName -Password $Password

	# first file
    $sequenceNo = 2000
    $jQueryUrl = "https://tenant.sharepoint.com/SiteAssets/jquery-2.2.3.js"
    Add-ScriptLinkAction -Context $Context -ScriptSrc $jQueryUrl -Sequence $sequenceNo
	
	# second file
	$sequenceNo = 2001
    $jQueryUrl = "https://tenant.sharepoint.com/SiteAssets/o365-simple-menu.js"
    Add-ScriptLinkAction -Context $Context -ScriptSrc $jQueryUrl -Sequence $sequenceNo

    $context.Dispose()
}


Activate-JS -SiteUrl $SiteUrl -UserName $UserName -Password $Password