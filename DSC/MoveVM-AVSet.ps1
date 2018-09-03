Install-Module AzureRm.AvailabilitySetManagement

Add-AzureRmAccount

#Select-AzureRmSubscription -SubscriptionID "your subscription ID"

Get-Command -Module AzureRm.AvailabilitySetManagement

New-AzureRmAvailabilitySet -Location "westus" -Name "SP2016-AS" -ResourceGroupName "DEV_US_RG" -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2

# ADD
Add-AzureRmAvSetVmToAvailabilitySet -ResourceGroupName "DEV_US_RG" -VMName "SP2016-WFE1" -OsType windows -AvailabilitySet "SP2016-AS"

# REMOVE
# Remove-AzureRmAvSetVmFromAvailabilitySet -ResourceGroupName "DEV_US_RG" -VMName "SP2016-WFE1" -OsType windows