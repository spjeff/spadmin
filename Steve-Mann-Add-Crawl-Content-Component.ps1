# from http://stevemannspath.blogspot.com/2013/05/sharepoint-2013-search-add-query.html

# Get Search Service Instance and Start on New WFE Server
$ssi = Get-SPEnterpriseSearchServiceInstance -Identity 
Start-SPEnterpriseSearchServiceInstance -Identity $ssi
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity $env:computername

# Wait for Search Service Instance to come online
Get-SPEnterpriseSearchServiceInstance -Identity $ssi

# Clone the Active Search Topology
$ssa = Get-SPEnterpriseSearchServiceApplication
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone –SearchTopology $active


# ---
# Add the New Query Content Processing
New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $ssi
New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $ssi

# Activate  the Cloned Search Topology
Set-SPEnterpriseSearchTopology -Identity $clone

# Optionally Review new topology
Get-SPEnterpriseSearchTopology -Active -SearchApplication $ssa

# Monitor/Verify the Search Status
Get-SPEnterpriseSearchStatus -SearchApplication $ssa
