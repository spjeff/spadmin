[CmdletBinding()]
param (
	[Parameter(Mandatory=$true, ValueFromPipeline=$false, HelpMessage='URL of site collection')]
	[string]$url
)

# Check in documents with no published version.
function CheckInDocs ($url) {
    $site = Get-SPSite $url
	# Loop all webs
    foreach($web in $site.AllWebs) {
		# Only Document Libraries
        foreach($list in $web.GetListsOfType([Microsoft.SharePoint.SPBaseType]::DocumentLibrary)) {
			# Take over checkout
            $list.CheckedOutFiles | % { $_.TakeOverCheckOut() }
			# Force check in
            $list.CheckedOutFiles | % {
                $item = $list.GetItemById($_.ListItemId)
                $item.File.CheckIn("File checked in by administrator")
                Write-Host $item.File.ServerRelativeUrl -NoNewline; Write-Host " Checked in " -ForegroundColor Green
            }
        }
		# Clean memory
        $web.dispose();
    }
    $site.dispose();
}

# Invoke
CheckInDocs $url