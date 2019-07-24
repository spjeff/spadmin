# from https://docs.microsoft.com/en-us/sharepoint/administration/flush-the-blob-cache
$webApp = Get-SPWebApplication
foreach ($wa in $webApp) {
	[Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($wa)
	Write-Host "Flushed the BLOB cache for:" $wa
}