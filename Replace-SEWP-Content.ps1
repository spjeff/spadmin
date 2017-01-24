<#
.SYNOPSIS
	Update SEWP (Script Editor Web Part) and CEWP (Content Editor Web Part) internal text.
.DESCRIPTION
	Loops all child webs in a given site collection.  Locate ASPX web part pages to replace SEWP (Script Editor Web Part) and CEWP (Content Editor Web Part) internal text.  Support read only mode (no changes).

	Comments and suggestions always welcome!  spjeff@spjeff.com or @spjeff
.NOTES
	File Namespace	: Replace-SEWP-Content.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.12
	Last Modified	: 01-24-2017
.LINK
	Source Code
	http://www.github.com/spjeff/
#>

param(
	[string]$url,					# Target Site Collection URL.  Loops all child webs.
	[string]$oldText,				# Old string to find.
	[string]$newText,				# New string to replace with.
	[switch]$readOnly,				# Read only operation.  Checks for Web Parts but will not change any content.
	[string]$overwriteWebPartTitle	# Name of Web Part Title to locate and update HTML source content.
)

# Plugins
Add-PSSnapIn Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null

function processPage ($web, $serverRelativeUrl) {
	# Inspect Web Parts on a given page
	$manager = $web.GetLimitedWebPartManager($serverRelativeUrl, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared);
	
	# Exclude already processed ASPX pages
	$found = $global:webPartsToUpdate |? {$_.FileURL -eq $manager.ServerRelativeUrl}
	if (!$found) {
		Write-Host "FILE: " $manager.ServerRelativeUrl
		$webParts = $manager.WebParts;

		foreach ($webPart in $webParts) {
			# Update Content Editor and Script Editor Web Parts
			$type = $null
			if ($webPart.GetType().ToString()-eq "Microsoft.SharePoint.WebPartPages.ContentEditorWebPart") {
				$content = $webPart.Content.InnerText
				if ($content -like "*$oldText*") {
					$type = "CEWP"
				}
			}
			if ($webPart.GetType().ToString() -eq "Microsoft.SharePoint.WebPartPages.ScriptEditorWebPart") {
				$content = $webPart.Content
				if ($content -like "*$oldText*") {
					$type = "SEWP"
				}
			}
			if ($type) {
				if ($overwriteWebPartTitle) {
					if ($overwriteWebPartTitle -ne $webPart.Title) {
						break
					}
				}
				# Used as a check before committing updates
				$o = New-Object PSObject;
				$o | Add-Member -MemberType Noteproperty -Name Title -Value $manger.Url
				$o | Add-Member -MemberType Noteproperty -Name Type -Value $webPart.GetType()
				$o | Add-Member -MemberType Noteproperty -Name Content -Value $content
				$o | Add-Member -MemberType Noteproperty -Name FileURL -Value $manager.ServerRelativeUrl
				$global:webPartsToUpdate += $o;
					
				if (!$readOnly) {
					Write-Host ("Updating: " + $webPart.Title)
					if ($type -eq "CEWP") {
						# Content Editor
						if ($overwriteWebPartTitle) {
							# Overwrite
							$xmlDoc = New-Object xml
							$newXmlElement = $xmlDoc.CreateElement("NewContent")
							$newXmlElement.InnerText = $newText
			 
							# Save
							$webPart.Content = $newXmlElement
							$manager.SaveChanges($webPart)
						} else {
							# Load Old Content
							$oldXmlElement = $webPart.Content
							$oldXmlContent = $oldXmlElement.InnerText
							
							# Replace
							$xmlDoc = New-Object xml
							$newXmlElement = $xmlDoc.CreateElement("NewContent")
							$newXmlElement.InnerText = $oldXmlContent.Replace($oldText, $newText)
			 
							# Save
							$webPart.Content = $newXmlElement
							$manager.SaveChanges($webPart)
						}
					}
					if ($type -eq "SEWP") {
						# Script Editor
						if ($overwriteWebPartTitle) {
							# Overwrite
							$webPart.Content = $newText
							$manager.SaveChanges($webPart)
						} else {
							# Save
							$old = $webPart.Content
							$new = $old.Replace($oldText, $newText)
							$webPart.Content = $new
							$manager.SaveChanges($webPart)
						}
					}
				}
			}
		}
	}
}

function processLibrary ($web, $documentLibraryTitle) {
	# Process all ASPX within a given Document Library
	try {
		$list = $web.Lists[$documentLibraryTitle]
		if ($list) {
			foreach ($item in $list.Items) {
				processPage $web $item.File.ServerRelativeUrl
			}
		}
	} catch {}
}

function processWeb ($web) {
	# Process only ASPX web part pages
	Write-Host "WEB:  " $web.Url
	
	# Homepage
	processPage $web $web.RootFolder.WelcomePage
	
	# /SitePages/ and /Pages/ library
	processLibrary $web "Site Pages"
	processLibrary $web "Pages"
}

$global:webPartsToUpdate = @()
function Main() {
	# Display mode
	if ($readOnly) {
		Write-Host "[READ ONLY MODE]" -ForegroundColor Yellow
	} else {
		Write-Host "[UPDATE MODE]" -ForegroundColor Green
	}
	
	# Process all webs in target Site Collection
	$site = Get-SPSite $url
	$site.AllWebs |% {processWeb $_}
	$site.Dispose()
	
	# Display
    Write-Host "`nDONE" -ForegroundColor Green
	$global:webPartsToUpdate | Format-List
}
Main