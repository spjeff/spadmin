# Connect into Azure AD
Connect-AzureAD

# Empty Collection
$coll = @()

# Loop through all Service Principals
$servicePrincipals = Get-AzureADServicePrincipal -All $true
foreach ($servicePrincipal in $servicePrincipals) {
    $objectId = $servicePrincipal.ObjectId
    $currentExpirationDate = (Get-AzureADServicePrincipalPasswordCredential -ObjectId $objectId).EndDate
    if ($currentExpirationDate) {
        Write-Host "$objectId,$currentExpirationDate" -ForegroundColor "Yellow"
        $coll += New-Object -TypeName PSObject -Property @{
            ObjectId = $objectId
            CurrentExpirationDate = $currentExpirationDate
        }
    }
}

# Display in Grid View
$coll | Out-GridView