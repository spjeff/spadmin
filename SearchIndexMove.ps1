function SearchIndexMove($SearchServiceName,$Server,$IndexLocation) {
	 Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0;
	 # Get the Search Service Application
	 $SSA = Get-SPServiceApplication -Name $SearchServiceName;
	 # Get the Search Service Instance
	 $Instance = Get-SPEnterpriseSearchServiceInstance -Identity $Server;
	 # Get the current Search topology
	 $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active;
	 # Create a clone of the current Search topology
	 $Clone = New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current;
	 # Add a new Index Component and the new Index location
	 New-SPEnterpriseSearchIndexComponent -SearchTopology $Clone -IndexPartition 0 -SearchServiceInstance $Instance -RootDirectory $IndexLocation | Out-Null;
	 if (!$?) { throw "ERROR: Check that `"$IndexLocation`" exists on `"$Server`""; }
	 # Set the new Search topology as "Active"
	 Set-SPEnterpriseSearchTopology -Identity $Clone;
	 # Remove the old Search topology
	 Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$false;
	 # There is an additional Index Component that needs removing
	 # Get the Search topology again
	 $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active;
	 # Create a clone of the current Search topology
	 $Clone = New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current;
	 # Get the Index Component and remove the old one
	 Get-SPEnterpriseSearchComponent -SearchTopology $Clone | ? {($_.GetType().Name -eq "IndexComponent") -and ($_.ServerName -eq $($Instance.Server.Address)) -and ($_.RootDirectory -ne $IndexLocation)} | Remove-SPEnterpriseSearchComponent -SearchTopology $Clone -Confirm:$false;
	 # Set the new Search topology as "Active"
	 Set-SPEnterpriseSearchTopology -Identity $Clone;
	 # Remove the old Search topology
	 Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$False;
	 Write-Host -ForegroundColor Green "Finished, remember to clean up the old Index location";
}

$IndexLocation = "G:\SPIndex"
SearchIndexMove -SearchServiceName "Search Service Application for SharePoint SSA" -Server "USATRAMEUX033" -IndexLocation $IndexLocation
# END
 