param(
   [string]$SiteUrl,   
   [string]$UserName, 
   [string]$Password   
)

. ".\UserCustomActions.ps1"

<#  
.SYNOPSIS  
    Enable jQuery Library        
.DESCRIPTION  
    Enable jQuery Library in Office 365/SharePoint Online site 
.EXAMPLE
    .\Activate-JQuery.ps1 -SiteUrl "https://tenant-public.sharepoint.com" -UserName "username@tenant.onmicrosoft.com" -Password "password"
#>
Function Activate-JQuery([string]$SiteUrl,[string]$UserName,[string]$Password)
{
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $context.Credentials = Get-SPOCredentials -UserName $UserName -Password $Password

    $sequenceNo = 2000
    $jQueryUrl = "https://tenant.sharepoint.com/SiteAssets/jquery-2.2.3.js"
    Add-ScriptLinkAction -Context $Context -ScriptSrc $jQueryUrl -Sequence $sequenceNo
	
	$sequenceNo = 2001
    $jQueryUrl = "https://tenant.sharepoint.com/SiteAssets/o365-simple-menu.js"
    Add-ScriptLinkAction -Context $Context -ScriptSrc $jQueryUrl -Sequence $sequenceNo

    $context.Dispose()
}


Activate-JQuery -SiteUrl $SiteUrl -UserName $UserName -Password $Password