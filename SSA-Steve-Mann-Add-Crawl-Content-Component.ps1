# from http://stevemannspath.blogspot.com/2013/05/sharepoint-2013-search-add-query.html

asnp *shar*

# Get Search Service Instance and Start on New WFE Server
$ssi = Get-SPEnterpriseSearchServiceInstance -Identity $env:computername
if (!$ssi) {
$ssi = Get-SPEnterpriseSearchServiceInstance -Identity "$($env:computername).$($env:userdnsdomain)"
}

# Start
Start-SPEnterpriseSearchServiceInstance -Identity $ssi
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $env:computername

# Wait for Search Service Instance to come online
Get-SPEnterpriseSearchServiceInstance -Identity $ssi

# Clone the Active Search Topology
$ssa = Get-SPEnterpriseSearchServiceApplication
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone –SearchTopology $active


# ---
# Add new components (6 - AACCIQ)
New-SPEnterpriseSearchAdminComponent -SearchTopology $clone -SearchServiceInstance $ssi
New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi
New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi
New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $ssi
New-SPEnterpriseSearchIndexComponent -SearchTopology $clone -SearchServiceInstance $env:computername -IndexPartition 0
New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi

# ---
# Remove components (6 - AACIQ)
$server = Get-SPServer $env:computername
$topology = Get-SPEnterpriseSearchComponent -SearchTopology $clone
$comp = $topology |? {$_.ServerId -eq $server.Id}
foreach ($c in $comp) {
$c.ComponentId
 Remove-SPEnterpriseSearchComponent -Identity $c -SearchTopology $clone -Confirm:$false
}


# Activate  the Cloned Search Topology
Set-SPEnterpriseSearchTopology -Identity $clone

# Optionally Review new topology
Get-SPEnterpriseSearchTopology -Active -SearchApplication $ssa

# Monitor/Verify the Search Status
Get-SPEnterpriseSearchStatus -SearchApplication $ssa
