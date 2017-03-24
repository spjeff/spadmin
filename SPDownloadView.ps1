# Download all files from a SharePoint Document Library view to the local folder over HTTP remotely.  
# No server side requirement, can run anywhere, including end user desktops.

param (
    $url,       # "http://portal/sites/test",
    $listID,    # "41E5FC8E-D174-4F48-AC3C-79F999A045D1",
    $viewID     # "5E9415B3-3C63-48AD-9DC2-A5A282B61790"
    )

# Current folder
$scriptpath = Split-Path $MyInvocation.MyCommand.Path
	
# Open file list
Write-Host "Opening $url"
$ows = "$url/_vti_bin/owssvr.dll?Cmd=Display&List={$listID}&View={$viewID}&XMLDATA=TRUE"
$owsList = "$url/_vti_bin/owssvr.dll?Cmd=ExportList&List={$listID}&XMLDATA=TRUE"
$r = Invoke-WebRequest $ows -UseDefaultCredentials
$rList = Invoke-WebRequest $owsList -UseDefaultCredentials
[xml]$xml = $r.Content
[xml]$xmlList = $rList.Content
$folder = $xmlList.List.Url

# Client
$client = New-Object System.Net.WebClient
$client.UseDefaultCredentials = $true

# Loop and download
foreach ($row in $xml.xml.data.row) {
    $name = $row.ows_LinkFilename
    $from = "$url/$folder/$name"
    $client.DownloadFile($from, "$scriptpath\$name")
}

Write-Host "DONE"