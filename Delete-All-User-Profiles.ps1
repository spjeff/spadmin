# from https://www.sharepointdiary.com/2015/07/remove-all-user-profiles-in-sharepoint-using-powershell.html

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Configuration Variables
$site = (Get-SPSite)[0]
 
#Get Objects
$ServiceContext  = Get-SPServiceContext -site $site
$UserProfileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($ServiceContext)
 
#Ger all User Profiles
$UserProfiles = $UserProfileManager.GetEnumerator()
  
# Loop through user profile
Foreach ($Profile in $UserProfiles) 
{
    write-host Removing User Profile: $Profile["AccountName"]
     
    #Remove User Profile
    $UserProfileManager.RemoveUserProfile($profile["AccountName"])
}