<#
.DESCRIPTION
    SPO Remove Site Owner Full Tenant (PowerShell PNP).  Removes give user login from all SharePoint Online site collections and OneDrive sites in a tenant.

    * Revoke Site Collection Admin (SCA) rights
    * Revoke Site Owners Group (where name ends with "*Owners")
	
    Comments and suggestions always welcome!  Please, use the issues panel at the project page.

.NOTES  
    File Name:  SPO-Remove-Site-Owner-Full-Tenant.ps1
    Author   :  Jeff Jones  - @spjeff
.LINK
    https://github.com/spjeff/spadmin
    https://studio.youtube.com/video/FfKhGZvemCs/edit
#>

Start-Transcript
# Connect to SharePoint Online tenant admin URL

# Configuration
$tenant = "TBD"
$AdminSiteURL = "https://$tenant-admin.sharepoint.com"
$loginsToRemove = @("i:0#.f|membership|USER@$tenant.onmicrosoft.com")
$appId = "TBD"
$appSecret = "TBD"

# Load Modules
Import-Module "PNP.PowerShell"

# Connect to SharePoint Online with PNP
Connect-PnPOnline -Url $AdminSiteURL -ClientId $appId -ClientSecret $appSecret -WarningAction "Ignore"

# Get all site collections and loop through them
$SiteCollections = Get-PnPTenantSite #-IncludeOneDriveSites
$SiteCollections  | Format-Table -AutoSize
$SiteCollections.Count

ForEach ($Site in $SiteCollections)
{
    # Write progress with % complete and current site URL
    Write-Progress -Activity "Removing Owners" -Status "$([math]::Round(($SiteCollections.IndexOf($Site) / $SiteCollections.Count) * 100))% Complete" -CurrentOperation $Site.Url

    # Connect to site collection
    Connect-PnPOnline -Url $Site.Url -ClientId $appId -ClientSecret $appSecret -warningaction Ignore

    # Get site owners
    $Owners = Get-PnPSiteCollectionAdmin

    # Loop through all owners and remove Site Collection Admin (SCA) rights
    ForEach ($Owner in $Owners)
    {
        # Remove Site Collection Admin (SCA) rights
        If ($loginsToRemove -contains $Owner.LoginName)
        {
            # Remove owner
            Remove-PnPSiteCollectionAdmin -Owners $Owner.LoginName
            Write-Host "Removed $($Owner.LoginName) from $($Site.Url)" -ForegroundColor "Yellow"
        }

        # Locate current site owners group where name ends with "Owners"
        $allGroup = Get-PnPGroup | Where-Object {$_.Title -like "*Owners"}

        # Loop all owners group and remove user if found
        ForEach ($Group in $allGroup)
        {
            ForEach ($User in $Group.Users)
            {
                If ($loginsToRemove -contains $User.LoginName)
                {
                    # Remove user from owners group
                    Remove-PnPGroupMember -LoginName $User.LoginName -Identity $Group.Title
                    Write-Host "Removed $($User.LoginName) from $($Group.Title) on $($Site.Url)" -ForegroundColor "Yellow"
                }
            }
        }

    }
}

Stop-Transcript