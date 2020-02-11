<#
Script filename: PNP-AppID-Upload.ps1

Register AppID:
https://tenant.sharepoint.com/sites/teamsite/_layouts/15/appregnew.aspx
(app domain = "localhost")

Grant Permissions on specific site:
https://tenant.sharepoint.com/sites/teamsite/_layouts/15/appinv.aspx

Site collection scope XML:
<AppPermissionRequests AllowAppOnlyPolicy="true">
    <AppPermissionRequest Scope="http://sharepoint/content/sitecollection" Right="FullControl" />
</AppPermissionRequests>
#>

# Read the secure password from a password file and decrypt it to a normal readable string
$KeyFile        = "PNP-AppID-Upload_AES_KEY_FILE.key"
$PasswordFile   = "PNP-AppID-Upload_AES_PASSWORD_FILE.txt"
 
# Convert the standard encrypted password stored in the password file to a secure string using the AES key file
$SecurePassword = ( (Get-Content $PasswordFile) | ConvertTo-SecureString -Key (Get-Content $KeyFile) ) 
# Write the secure password to unmanaged memory (specifically to a binary or basic string) 
$SecurePasswordInMemory = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword);      
# Read the plain-text password from memory and store it in a variable
$PasswordAsString = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecurePasswordInMemory);      
# Delete the password from the unmanaged memory (for security reasons)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecurePasswordInMemory);               

#Connect to SharePoint - AppID/Secret is unique for the site
Connect-PnPOnline -Url "https://tenant.sharepoint.com/sites/teamsite" -AppID "01ded96e-2790-4454-8ff2-5cecc307d724" -AppSecret $PasswordAsString

#Source location
$localPath = "C:\TEMP"

#destination library name
$spLib = "Shared Documents"

#collect all items in the source location
$reports = Get-ChildItem -Path $localPath -Recurse

#Upload all files found in location $localPath
foreach ($report in $reports)
{
    #Prepare folder path
    $repName = $report.Name
    $filePath = "$localPath\$repName"

    #Files with same name = overwritten with version history saved
    Add-PnPFile -Path $filePath -Folder $spLib
}
